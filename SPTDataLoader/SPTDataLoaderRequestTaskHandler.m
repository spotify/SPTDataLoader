/*
 * Copyright (c) 2015-2018 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import "SPTDataLoaderRequestTaskHandler.h"

#import "SPTDataLoaderResponse.h"
#import "SPTDataLoaderRequest.h"
#import "SPTDataLoaderRateLimiter.h"

#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"

#import "SPTDataLoaderExponentialTimer.h"

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const SPTDataLoaderRequestTaskHandlerMaxRedirects = 10;

static void *SPTDataLoaderRequestTaskHandlerContext = &SPTDataLoaderRequestTaskHandlerContext;
static NSString *const kCountOfBytesReceived = @"countOfBytesReceived";
static NSString *const kCountOfBytesSent = @"countOfBytesSent";
static NSString *const kCountOfBytesExpectedToReceive = @"countOfBytesExpectedToReceive";
static NSString *const kCountOfBytesExpectedToSend = @"countOfBytesExpectedToSend";

@interface SPTDataLoaderRequestTaskHandler ()

@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;

@property (nonatomic, weak) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;
@property (nonatomic, strong, nullable) SPTDataLoaderRateLimiter *rateLimiter;

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
@property (nonatomic, assign, getter = isObserving) BOOL observing;
@property (nonatomic, strong, readwrite) dispatch_queue_t retryQueue;

@end

@implementation SPTDataLoaderRequestTaskHandler

#pragma mark SPTDataLoaderRequestTaskHandler

+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
{
    return [[self alloc] initWithTask:task
                              request:request
               requestResponseHandler:requestResponseHandler
                          rateLimiter:rateLimiter];
}

- (instancetype)initWithTask:(NSURLSessionTask *)task
                     request:(SPTDataLoaderRequest *)request
      requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
{
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerMaximumTime = 60.0;
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerInitialTime = 1.0;

    self = [super init];
    if (self) {
        _task = task;
        [self addObserverForTask:_task];
        _request = request;
        _requestResponseHandler = requestResponseHandler;
        _rateLimiter = rateLimiter;

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

@synthesize task = _task;

- (NSURLSessionTask *)task {
    @synchronized(self) {
        return _task;
    }
}

- (void)setTask:(NSURLSessionTask * _Nonnull)task {
    @synchronized(self) {
        if (_task != task) {
            if (_task) {
                [self removeObserverForTask:_task];
            }
            
            _task = task;
            
            if (_task) {
                [self addObserverForTask:_task];
            }
        }
    }
}

- (void)receiveData:(NSData *)data
{
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        
        NSData *dataRange = [NSData dataWithBytes:bytes length:byteRange.length];

        if (self.request.chunks) {
            [self.requestResponseHandler receivedDataChunk:dataRange forResponse:self.response];
        } else {
            [self.receivedData appendData:dataRange];
        }
    }];
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
    
    return NSURLSessionResponseAllow;
}

- (BOOL)mayRedirect
{
    // Limit the amount of possible redirects
    if (++self.redirectCount > SPTDataLoaderRequestTaskHandlerMaxRedirects) {
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

#pragma mark KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSString *, id> *)change
                       context:(nullable  void *)context
{
    if (context == SPTDataLoaderRequestTaskHandlerContext) {
        NSURLSessionTask *task = (NSURLSessionTask *)object;
        if ([task isKindOfClass:[NSURLSessionTask class]]) {
            id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = self.requestResponseHandler;
            if ([keyPath isEqualToString:kCountOfBytesReceived] || [keyPath isEqualToString:kCountOfBytesExpectedToReceive]) {
                [requestResponseHandler updatedCountOfBytesReceived:self.task.countOfBytesReceived
                                      countOfBytesExpectedToReceive:self.task.countOfBytesExpectedToReceive
                                                         forRequest:self.request];
            } else if ([keyPath isEqualToString:kCountOfBytesSent] || [keyPath isEqualToString:kCountOfBytesExpectedToSend]) {
                [requestResponseHandler updatedCountOfBytesSent:self.task.countOfBytesSent
                                     countOfBytesExpectedToSend:self.task.countOfBytesExpectedToSend
                                                     forRequest:self.request];
            }
        }
    }
}

- (void)addObserverForTask:(NSURLSessionTask *)task
{
    NSAssert(!self.isObserving, @"Observer is already registered for task");
    if (self.isObserving) {
        return;
    }
    
    self.observing = YES;
    
    [task addObserver:self
            forKeyPath:kCountOfBytesReceived
               options:NSKeyValueObservingOptionNew
               context:SPTDataLoaderRequestTaskHandlerContext];
    [task addObserver:self
            forKeyPath:kCountOfBytesSent
               options:NSKeyValueObservingOptionNew
               context:SPTDataLoaderRequestTaskHandlerContext];
    [task addObserver:self
            forKeyPath:kCountOfBytesExpectedToReceive
               options:NSKeyValueObservingOptionNew
               context:SPTDataLoaderRequestTaskHandlerContext];
    [task addObserver:self
            forKeyPath:kCountOfBytesExpectedToSend
               options:NSKeyValueObservingOptionNew
               context:SPTDataLoaderRequestTaskHandlerContext];
}

- (void)removeObserverForTask:(NSURLSessionTask *)task
{
    NSAssert(self.isObserving, @"Observer is not registered");
    if (!self.isObserving) {
        return;
    }
    
    self.observing = NO;
    
    [task removeObserver:self
               forKeyPath:kCountOfBytesReceived
                  context:SPTDataLoaderRequestTaskHandlerContext];
    [task removeObserver:self
               forKeyPath:kCountOfBytesSent
                  context:SPTDataLoaderRequestTaskHandlerContext];
    [task removeObserver:self
               forKeyPath:kCountOfBytesExpectedToReceive
                  context:SPTDataLoaderRequestTaskHandlerContext];
    [task removeObserver:self
               forKeyPath:kCountOfBytesExpectedToSend
                  context:SPTDataLoaderRequestTaskHandlerContext];
}

#pragma mark NSObject

- (void)dealloc
{
    [self completeIfInFlight];
    [self removeObserverForTask:_task];
}

@end

NS_ASSUME_NONNULL_END
