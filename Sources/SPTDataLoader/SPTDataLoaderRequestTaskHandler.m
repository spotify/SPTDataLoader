/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SPTDataLoaderRequestTaskHandler.h"

#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"

#import <SPTDataLoader/SPTDataLoaderExponentialTimer.h>

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const SPTDataLoaderRequestTaskHandlerMaxRedirects = 10;

@interface SPTDataLoaderRequestTaskHandler ()

@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;

@property (nonatomic, weak) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;
@property (nonatomic, strong, nullable) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, weak, readonly) id<SPTDataLoaderRequestTaskHandlerDelegate> delegate;

@property (nonatomic, strong) SPTDataLoaderResponse *response;
@property (nonatomic, strong, nullable) NSMutableData *receivedData;
@property (nonatomic, assign) CFAbsoluteTime absoluteStartTime;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, assign) NSUInteger waitCount;
@property (nonatomic, assign) NSUInteger redirectCount;
@property (nonatomic, copy) dispatch_block_t executionBlock;
@property (nonatomic, strong) SPTDataLoaderExponentialTimer *exponentialTimer;

@property (nonatomic, assign) BOOL calledSuccessfulResponse;
@property (nonatomic, assign) BOOL calledFailedResponse;
@property (nonatomic, assign) BOOL calledCancelledRequest;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, strong, readwrite) dispatch_queue_t retryQueue;
@property (nonatomic, assign) BOOL shouldStopRedirection;

@end

@implementation SPTDataLoaderRequestTaskHandler

#pragma mark SPTDataLoaderRequestTaskHandler

+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                            delegate:(id<SPTDataLoaderRequestTaskHandlerDelegate>)delegate
{
    return [[self alloc] initWithTask:task
                              request:request
               requestResponseHandler:requestResponseHandler
                          rateLimiter:rateLimiter
                             delegate:delegate];
}

- (instancetype)initWithTask:(NSURLSessionTask *)task
                     request:(SPTDataLoaderRequest *)request
      requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                    delegate:(id<SPTDataLoaderRequestTaskHandlerDelegate>)delegate
{
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerMaximumTime = 60.0;
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerInitialTime = 1.0;

    self = [super init];
    if (self) {
        _task = task;
        _request = request;
        _requestResponseHandler = requestResponseHandler;
        _rateLimiter = rateLimiter;
        _delegate = delegate;
        _shouldStopRedirection = request.shouldStopRedirection;

        __weak __typeof(self) weakSelf = self;
        _executionBlock = ^{
            [weakSelf checkRateLimiterAndExecute];
        };
        _exponentialTimer = [SPTDataLoaderExponentialTimer exponentialTimerWithInitialTime:SPTDataLoaderRequestTaskHandlerInitialTime
                                                                                   maxTime:SPTDataLoaderRequestTaskHandlerMaximumTime];
        _retryQueue = dispatch_get_main_queue();
    }
    
    return self;
}

- (void)receiveData:(NSData *)data
{
    if (self.request.chunks) {
        [self.requestResponseHandler receivedDataChunk:data forResponse:self.response];
    } else {
        if (!self.receivedData) {
            self.receivedData = [data mutableCopy];
        } else {
            [self.receivedData appendData:data];
        }
    }
}

- (nullable SPTDataLoaderResponse *)completeWithError:(nullable NSError *)error
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = self.requestResponseHandler;
    if (!self.response) {
        self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:nil];
    }
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [requestResponseHandler cancelledRequest:self.request];
        self.calledCancelledRequest = YES;
        self.cancelled = YES;
        return nil;
    }
    
    [self.rateLimiter executedRequest:self.request];
    
    if (error) {
        self.response.error = error;
    }
    
    self.response.body = self.receivedData;
    self.response.requestTime = CFAbsoluteTimeGetCurrent() - self.absoluteStartTime;
    
    if (self.response.retryAfter) {
        [self.rateLimiter setRetryAfter:self.response.retryAfter.timeIntervalSinceReferenceDate
                                 forURL:self.response.request.URL];
    }
    
    if (self.response.error) {
        if ([self.response shouldRetry]) {
            if (self.retryCount++ != self.request.maximumRetryCount) {
                [self.delegate requestTaskHandlerNeedsNewTask:self];
                [self start];
                return nil;
            }
        }
        [requestResponseHandler failedResponse:self.response];
        self.calledFailedResponse = YES;
        return self.response;
    }
    
    [requestResponseHandler successfulResponse:self.response];
    self.calledSuccessfulResponse = YES;
    return self.response;
}

- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response
{
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:response];
    [self.requestResponseHandler receivedInitialResponse:self.response];

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.expectedContentLength > 0) {
            self.receivedData = [NSMutableData dataWithCapacity:(NSUInteger)httpResponse.expectedContentLength];
        }
    }
    
    if (!self.receivedData) {
        self.receivedData = [NSMutableData data];
    }

    if (self.request.backgroundPolicy == SPTDataLoaderRequestBackgroundPolicyOnDemand) {
        return NSURLSessionResponseBecomeDownload;
    } else {
        return NSURLSessionResponseAllow;
    }
}

- (BOOL)mayRedirect
{
    // Limit the amount of possible redirects
    if (++self.redirectCount > SPTDataLoaderRequestTaskHandlerMaxRedirects || self.shouldStopRedirection) {
        return NO;
    }

    return YES;
}

- (void)start
{
    self.started = YES;
    self.executionBlock();
}

- (void)provideNewBodyStreamWithCompletion:(void (^)(NSInputStream * _Nonnull))completionHandler
{
    [self.requestResponseHandler needsNewBodyStream:completionHandler forRequest:self.request];
}

- (void)noteWaitingForConnectivity
{
    [self.requestResponseHandler requestIsWaitingForConnectivity:self.request];
}

- (void)checkRateLimiterAndExecute
{
    NSTimeInterval waitTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request];
    if (waitTime == 0.0) {
        [self checkRetryLimiterAndExecute];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(waitTime * NSEC_PER_SEC)),
                       self.retryQueue,
                       self.executionBlock);
    }
}

- (void)checkRetryLimiterAndExecute
{
    if (self.waitCount < self.retryCount) {
        self.waitCount++;
        if (self.waitCount == 1) {
            self.executionBlock();
        } else {
            NSTimeInterval waitTime = self.exponentialTimer.timeIntervalAndCalculateNext;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(waitTime * NSEC_PER_SEC)),
                           self.retryQueue,
                           self.executionBlock);
        }
        return;
    }

    self.receivedData = nil;
    self.absoluteStartTime = CFAbsoluteTimeGetCurrent();
    [self.task resume];
}

- (void)completeIfInFlight
{
    // Always call the last error the request completed with if retrying
    if (self.started && !self.calledCancelledRequest && !self.calledFailedResponse && !self.calledSuccessfulResponse) {
        [self completeWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    }
}

#pragma mark NSObject

- (void)dealloc
{
    [self completeIfInFlight];
}

@end

NS_ASSUME_NONNULL_END
