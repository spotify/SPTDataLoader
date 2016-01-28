/*
 * Copyright (c) 2015-2016 Spotify AB.
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
#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderRequestResponseHandlerMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfSuccessfulDataResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfReceivedInitialResponseCalls;
@property (nonatomic, strong, readwrite) SPTDataLoaderResponse *lastReceivedResponse;

@end

@implementation SPTDataLoaderRequestResponseHandlerMock

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfSuccessfulDataResponseCalls++;
    self.lastReceivedResponse = response;
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfFailedResponseCalls++;
    self.lastReceivedResponse = response;
    if (self.failedResponseBlock) {
        self.failedResponseBlock();
    }
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCancelledRequestCalls++;
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfReceivedDataRequestCalls++;
    self.lastReceivedResponse = response;
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfReceivedInitialResponseCalls++;
    self.lastReceivedResponse = response;
}

- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request
{
    return self.isAuthorising;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
}

@end
