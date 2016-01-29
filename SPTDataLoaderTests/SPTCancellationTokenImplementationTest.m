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
@import XCTest;

#import "SPTCancellationTokenImplementation.h"

#import "SPTCancellationTokenDelegateMock.h"

@interface SPTCancellationTokenImplementationTest : XCTestCase

@property (nonatomic, strong) SPTCancellationTokenImplementation *cancellationToken;

@property (nonatomic, strong) id<SPTCancellationTokenDelegate> delegate;

@end

@implementation SPTCancellationTokenImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.delegate = [SPTCancellationTokenDelegateMock new];
    self.cancellationToken = [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:self.delegate cancelObject:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTCancellationTokenImplementationTest

- (void)testCancel
{
    [self.cancellationToken cancel];
    SPTCancellationTokenDelegateMock *delegateMock = (SPTCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1u, @"The delegate cancel method should only have been called once");
    XCTAssertTrue(self.cancellationToken.cancelled, @"The cancellation token did not set itself to cancelled despite being cancelled");
}

- (void)testMultipleCancelsOnlyMakeOneDelegateCall
{
    [self.cancellationToken cancel];
    [self.cancellationToken cancel];
    SPTCancellationTokenDelegateMock *delegateMock = (SPTCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1u, @"The delegate cancel method should only have been called once");
}

@end
