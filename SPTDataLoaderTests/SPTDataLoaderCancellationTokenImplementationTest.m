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

#import "SPTDataLoaderCancellationTokenImplementation.h"

#import "SPTDataLoaderCancellationTokenDelegateMock.h"

@interface SPTDataLoaderCancellationTokenImplementationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderCancellationTokenImplementation *cancellationToken;

@property (nonatomic, strong) id<SPTDataLoaderCancellationTokenDelegate> delegate;

@end

@implementation SPTDataLoaderCancellationTokenImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.delegate = [SPTDataLoaderCancellationTokenDelegateMock new];
    self.cancellationToken = [SPTDataLoaderCancellationTokenImplementation cancellationTokenImplementationWithDelegate:self.delegate cancelObject:nil];
}

#pragma mark SPTCancellationTokenImplementationTest

- (void)testCancel
{
    [self.cancellationToken cancel];
    SPTDataLoaderCancellationTokenDelegateMock *delegateMock = (SPTDataLoaderCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1u, @"The delegate cancel method should only have been called once");
    XCTAssertTrue(self.cancellationToken.cancelled, @"The cancellation token did not set itself to cancelled despite being cancelled");
}

- (void)testMultipleCancelsOnlyMakeOneDelegateCall
{
    [self.cancellationToken cancel];
    [self.cancellationToken cancel];
    SPTDataLoaderCancellationTokenDelegateMock *delegateMock = (SPTDataLoaderCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1u, @"The delegate cancel method should only have been called once");
}

@end
