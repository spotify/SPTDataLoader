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
#import <XCTest/XCTest.h>

#import "SPTCancellationTokenFactoryImplementation.h"

#import "SPTCancellationTokenDelegateMock.h"

@interface SPTCancellationTokenFactoryImplementationTest : XCTestCase

@property (nonatomic, strong) SPTCancellationTokenFactoryImplementation *cancellationTokenFactory;

@end

@implementation SPTCancellationTokenFactoryImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.cancellationTokenFactory = [SPTCancellationTokenFactoryImplementation new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTCancellationTokenFactoryImplementationTest

- (void)testCreateCancellationToken
{
    id<SPTCancellationTokenDelegate> delegate = [SPTCancellationTokenDelegateMock new];
    id<SPTCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:delegate cancelObject:nil];
    XCTAssertNotNil(cancellationToken, @"The factory did not provide a valid cancellation token");
    XCTAssertEqual(delegate, cancellationToken.delegate, @"The factory did not set the delegate on the cancellation token");
}

@end
