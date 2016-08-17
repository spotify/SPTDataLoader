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

#import "SPTDataLoaderFactory.h"

#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderAuthoriserMock.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandlerDelegate, SPTDataLoaderAuthoriserDelegate>

@property (nonatomic, strong, readwrite) dispatch_queue_t requestTimeoutQueue;

@end

@interface SPTDataLoaderFactoryTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderFactory *factory;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *delegate;
@property (nonatomic, strong) SPTDataLoaderAuthoriserMock *authoriserMock;

@end

@implementation SPTDataLoaderFactoryTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.delegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.authoriserMock = [SPTDataLoaderAuthoriserMock new];
    self.factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:self.delegate
                                                                                 authorisers:@[ self.authoriserMock ]];
}

#pragma mark SPTDataLoaderFactoryTest

- (void)testNotNil
{
    XCTAssertNotNil(self.factory, @"The factory created should not be nil");
}

- (void)testCreateDataLoader
{
    SPTDataLoader *dataLoader = [self.factory createDataLoader];
    XCTAssertNotNil(dataLoader, @"The data loader created by the factory is nil");
}

- (void)testSuccessfulResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory successfulResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfSuccessfulDataResponseCalls, 1u, @"The factory did not relay a successful response to the correct handler");
}

- (void)testFailedResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory failedResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfFailedResponseCalls, 1u, @"The factory did not relay a failed response to the correct handler");
}

- (void)testCancelledRequest
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    [self.factory cancelledRequest:request];
    XCTAssertEqual(requestResponseHandler.numberOfCancelledRequestCalls, 1u, @"The factory did not relay a cancelled request to the correct handler");
}

- (void)testReceivedDataChunk
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory receivedDataChunk:[NSData new] forResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfReceivedDataRequestCalls, 1u, @"The factory did not relay a received data chunk response to the correct handler");
}

- (void)testReceivedInitialResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory receivedInitialResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfReceivedInitialResponseCalls, 1u, @"The factory did not relay a received data chunk response to the correct handler");
}

- (void)testShouldAuthoriseRequest
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory *factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:nil authorisers:@[ authoriser ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    BOOL shouldAuthorise = [factory shouldAuthoriseRequest:request];
    XCTAssertTrue(shouldAuthorise, @"The factory should mark the request as authorisable");
}

- (void)testShouldNotAuthoriseRequest
{
    self.authoriserMock.enabled = NO;
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    BOOL shouldAuthorise = [self.factory shouldAuthoriseRequest:request];
    XCTAssertFalse(shouldAuthorise, @"The factory should not mark the request as authorisable");
}

- (void)testAuthoriseRequest
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory *factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:nil authorisers:@[ authoriser ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [factory authoriseRequest:request];
    XCTAssertEqual(authoriser.numberOfCallsToAuthoriseRequest, 1u, @"The factory did not send an authorise request to the authoriser");
}

- (void)testOfflineChangesCachePolicy
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    self.factory.offline = YES;
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    XCTAssertEqual(request.cachePolicy, NSURLRequestReturnCacheDataDontLoad, @"The factory did not change the request cache policy to no load when being set to offline");
}

- (void)testRelayToDelegateWhenPerformingRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.factory requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    XCTAssertEqual(request, self.delegate.lastRequestPerformed, @"The factory did not relay the perform request to it's delegate");
}

- (void)testRelayAuthorisingSuccessToDelegate
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory dataLoaderAuthoriser:authoriser authorisedRequest:request];
    XCTAssertEqual(request, self.delegate.lastRequestAuthorised, @"The factory did not relay the request authorisation success to it's delegate");
}

- (void)testRelayAuthorisationFailureToDelegate
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    NSError *error = [NSError new];
    [self.factory dataLoaderAuthoriser:authoriser didFailToAuthoriseRequest:request withError:error];
    XCTAssertEqual(request, self.delegate.lastRequestFailed, @"The factory did not relay the request authorisation failure to it's delegate");
}

- (void)testRetryAuthorisation
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    response.error = [NSError errorWithDomain:@"" code:SPTDataLoaderResponseHTTPStatusCodeUnauthorised userInfo:nil];
    [self.factory failedResponse:response];
    [self.factory failedResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfFailedResponseCalls, 1u, @"The factory should only fail once after two authorisation failures");
}

- (void)testRequestTimeout
{
    self.factory.requestTimeoutQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Test timeout executes in time given"];
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    requestResponseHandler.failedResponseBlock = ^ {
        [expectation fulfill];
    };
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.timeout = 0.1;
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqual(requestResponseHandler.numberOfFailedResponseCalls, 1u, @"The request should have been cancelled");
}

- (void)testForwardCancelToRequestResponseHandlerDelegate
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler cancelRequest:request];
    XCTAssertEqualObjects(request, self.delegate.lastRequestCancelled);
}

@end
