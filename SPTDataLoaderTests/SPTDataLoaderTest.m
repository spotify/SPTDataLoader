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
#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequest.h"

#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"
#import "SPTDataLoaderDelegateMock.h"
#import "SPTDataLoaderCancellationTokenDelegateMock.h"
#import "SPTDataLoaderCancellationTokenImplementation.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderCancellationTokenFactoryMock.h"

@interface SPTDataLoaderTest : XCTestCase

@property (nonatomic, strong) SPTDataLoader *dataLoader;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *requestResponseHandlerDelegate;

@property (nonatomic, strong) SPTDataLoaderDelegateMock *delegate;
@property (nonatomic, strong, readwrite) SPTDataLoaderCancellationTokenFactoryMock *factoryMock;

@end

@implementation SPTDataLoaderTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.requestResponseHandlerDelegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.factoryMock = [SPTDataLoaderCancellationTokenFactoryMock new];
    self.dataLoader = [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self.requestResponseHandlerDelegate
                                                         cancellationTokenFactory:self.factoryMock];
    self.delegate = [SPTDataLoaderDelegateMock new];
    self.dataLoader.delegate = self.delegate;
}

#pragma mark SPTDataLoaderTest

- (void)testNotNil
{
    XCTAssertNotNil(self.dataLoader, @"The data loader should not be nil after construction");
}

- (void)testPerformRequestRelayedToRequestResponseHandlerDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    XCTAssertNotNil(self.requestResponseHandlerDelegate.lastRequestPerformed, @"Their should be a valid last request performed");
}

- (void)testCancelAllLoads
{
    SPTDataLoaderCancellationTokenDelegateMock *cancellationTokenDelegateMock = [SPTDataLoaderCancellationTokenDelegateMock new];
    self.factoryMock.overridingDelegate = cancellationTokenDelegateMock;
    NSUInteger maximumRequests = 5;
    for (NSUInteger i = 0; i < maximumRequests; ++i) {
        SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
        [self.dataLoader performRequest:request];
    }
    [self.dataLoader cancelAllLoads];
    XCTAssertEqual(cancellationTokenDelegateMock.numberOfCallsToCancellationTokenDidCancel,
                   maximumRequests,
                   @"The cancellation tokens delegate was not called");
}

- (void)testRelaySuccessfulResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader successfulResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToSuccessfulResponse, 1u, @"The data loader did not relay a successful response to the delegate");
}

- (void)testRelayFailureResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader failedResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToErrorResponse, 1u, @"The data loader did not relay a error response to the delegate");
}

- (void)testRelayCancelledRequestToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    [self.dataLoader cancelledRequest:request];
    XCTAssertEqual(self.delegate.numberOfCallsToCancelledRequest, 1u, @"The data loader did not relay a cancelled request to the delegate");
}

- (void)testRelayReceivedDataChunkToDelegate
{
    self.delegate.supportChunks = YES;
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedDataChunk:[NSData new] forResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceiveDataChunk, 1u, @"The data loader did not relay a received data chunk response to the delegate");
}

- (void)testRelayReceivedInitialResponseToDelegate
{
    self.delegate.supportChunks = YES;
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedInitialResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceivedInitialResponse, 1u, @"The data loader did not relay a received initial response to the delegate");
}

- (void)testDelegateCallbackOnSeparateQueue
{
    self.dataLoader.delegateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Test delegate callback on separate queue"];
    self.delegate.receivedSuccessfulBlock = ^ {
        [expectation fulfill];
    };
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader successfulResponse:response];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqual(self.delegate.numberOfCallsToSuccessfulResponse, 1u, @"The data loader did not relay a successful response to the delegate");
}

- (void)testErrorDelegateCallbackWhenMismatchInChunkSupport
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    [self.dataLoader performRequest:request];
    XCTAssertEqual(self.delegate.numberOfCallsToErrorResponse, 1u);
}

- (void)testNoCallsToReceiveInitialResponseIfRequestDoesNotSupportChunks
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = NO;
    [self.dataLoader performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedInitialResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceivedInitialResponse, 0u);
}

- (void)testSuccessfulResponseDoesNotEchoToDelegateWithUntrackedRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader successfulResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToSuccessfulResponse, 0u);
}

- (void)testSuccessfulResponseDoesNotEchoToDelegateWithFailedRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader failedResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToErrorResponse, 0u);
}

- (void)testSuccessfulResponseDoesNotEchoToDelegateWithCancelledRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader failedResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToCancelledRequest, 0u);
}

- (void)testSuccessfulResponseDoesNotEchoToDelegateWithReceivedDataChunkRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    NSData *data = [NSData data];
    [self.dataLoader receivedDataChunk:data forResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceiveDataChunk, 0u);
}

- (void)testSuccessfulResponseDoesNotEchoToDelegateWithReceivedInitialResponseRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedInitialResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceivedInitialResponse, 0u);
}

- (void)testCancellingCancellationTokenFiresDelegateCancelMessage
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    id<SPTDataLoaderCancellationToken> cancellationToken = [self.dataLoader performRequest:request];
    [cancellationToken cancel];
    XCTAssertEqual(self.delegate.numberOfCallsToCancelledRequest, 1u);
}

@end
