/*
 Copyright (c) 2015-2020 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderBlockWrapper.h>

#import "SPTDataLoaderImplementation+Private.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderCancellationTokenFactoryMock.h"

@interface SPTDataLoaderBlockWrapperTest : XCTestCase

@property (nonatomic, strong) SPTDataLoader *dataLoader;
@property (nonatomic, strong) SPTDataLoaderBlockWrapper *dataLoaderBlockWrapper;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *requestResponseHandlerDelegate;

@property (nonatomic, strong, readwrite) SPTDataLoaderCancellationTokenFactoryMock *factoryMock;

@end

@implementation SPTDataLoaderBlockWrapperTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.requestResponseHandlerDelegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.factoryMock = [SPTDataLoaderCancellationTokenFactoryMock new];
    self.dataLoader = [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self.requestResponseHandlerDelegate
                                                         cancellationTokenFactory:self.factoryMock];
    self.dataLoaderBlockWrapper = [[SPTDataLoaderBlockWrapper alloc] initWithDataLoader:self.dataLoader];
}

#pragma mark SPTDataLoaderTest

- (void)testNotNil
{
    XCTAssertNotNil(self.dataLoaderBlockWrapper, @"The data loader block wrapper should not be nil after construction");
}

- (void)testPerformRequestRelayedToRequestResponseHandlerDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoaderBlockWrapper performRequest:request completion:^(SPTDataLoaderResponse * _Nonnull response, NSError * _Nullable error) {

    }];
    XCTAssertNotNil(self.requestResponseHandlerDelegate.lastRequestPerformed, @"Their should be a valid last request performed");
}

- (void)testRelaySuccessfulResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *mockResponse = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Expected response"];
    [self.dataLoaderBlockWrapper performRequest:request completion:^(SPTDataLoaderResponse * _Nonnull response, NSError * _Nullable error) {
        XCTAssertTrue(response == mockResponse && error == nil);
        [expectation fulfill];
    }];
    [self.dataLoader successfulResponse:mockResponse];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testRelayFailureResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    NSError *expectedError = [NSError errorWithDomain:@"random.domain" code:33 userInfo:nil];
    SPTDataLoaderResponse *mockResponse = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    mockResponse.error = expectedError;
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Expected response"];
    [self.dataLoaderBlockWrapper performRequest:request completion:^(SPTDataLoaderResponse * _Nonnull response, NSError * _Nullable error) {
        XCTAssertTrue(response == mockResponse && error == expectedError);
        [expectation fulfill];
    }];
    [self.dataLoader failedResponse:mockResponse];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end
