/*
 * Copyright (c) 2015 Spotify AB.
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

#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTExpTime.h"

@interface SPTDataLoaderRequestTaskHandler ()

@property (nonatomic, weak) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;

@property (nonatomic, strong) SPTDataLoaderResponse *response;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) CFAbsoluteTime absoluteStartTime;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, assign) NSUInteger waitCount;
@property (nonatomic, copy) dispatch_block_t executionBlock;
@property (nonatomic, strong) SPTExpTime *expTime;

@property (nonatomic, assign) BOOL calledSuccessfulResponse;
@property (nonatomic, assign) BOOL calledFailedResponse;
@property (nonatomic, assign) BOOL calledCancelledRequest;
@property (nonatomic, assign) BOOL started;

@end

@implementation SPTDataLoaderRequestTaskHandler

#pragma mark SPTDataLoaderRequestTaskHandler

+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    return [[self alloc] initWithTask:task
                              request:request
               requestResponseHandler:requestResponseHandler
                          rateLimiter:rateLimiter];
}

- (instancetype)initWithTask:(NSURLSessionTask *)task
                     request:(SPTDataLoaderRequest *)request
      requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerMaximumTime = 60.0;
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _task = task;
    _request = request;
    _requestResponseHandler = requestResponseHandler;
    _rateLimiter = rateLimiter;
    
    __weak __typeof(self) weakSelf = self;
    _executionBlock = ^ {
        [weakSelf checkRateLimiterAndExecute];
    };
    _expTime = [SPTExpTime expTimeWithInitialTime:0.0 maxTime:SPTDataLoaderRequestTaskHandlerMaximumTime];
    
    return self;
}

- (void)receiveData:(NSData *)data
{
    if (self.request.chunks) {
        [self.requestResponseHandler receivedDataChunk:data forResponse:self.response];
    } else {
        [self.receivedData appendData:data];
    }
}

- (void)completeWithError:(NSError *)error
{
    if (!self.response) {
        self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:nil];
    }
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [self.requestResponseHandler cancelledRequest:self.request];
        self.calledCancelledRequest = YES;
        return;
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
                return;
            }
        }
        [self.requestResponseHandler failedResponse:self.response];
        self.calledFailedResponse = YES;
        return;
    }
    
    [self.requestResponseHandler successfulResponse:self.response];
    self.calledSuccessfulResponse = YES;
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

- (void)start
{
    self.started = YES;
    self.executionBlock();
}

- (void)checkRateLimiterAndExecute
{
    NSTimeInterval waitTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request];
    if (waitTime == 0.0) {
        [self checkRetryLimiterAndExecute];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), self.executionBlock);
    }
}

- (void)checkRetryLimiterAndExecute
{
    if (self.waitCount < self.retryCount) {
        self.waitCount++;
        NSTimeInterval waitTime = self.expTime.timeIntervalAndCalculateNext;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), self.executionBlock);
        return;
    }
    
    self.absoluteStartTime = CFAbsoluteTimeGetCurrent();
    [self.task resume];
}

#pragma mark NSObject

- (void)dealloc
{
    // Always call the last error the request completed with if retrying
    if (_started && !_calledCancelledRequest && !_calledFailedResponse && !_calledSuccessfulResponse) {
        [self completeWithError:nil];
    }
}

@end
