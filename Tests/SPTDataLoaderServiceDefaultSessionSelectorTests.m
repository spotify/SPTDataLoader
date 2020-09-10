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

#import "SPTDataLoaderServiceSessionSelector.h"

#import "NSURLSessionDelegateMock.h"

#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <XCTest/XCTest.h>

@interface SPTDataLoaderServiceDefaultSessionSelectorTests : XCTestCase

@property (nonatomic, strong) SPTDataLoaderServiceDefaultSessionSelector *sessionSelector;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) id<NSURLSessionDelegate> sessionDelegateMock;
@property (nonatomic, strong) NSURL *testURL;
@property (nonatomic, strong) SPTDataLoaderRequest *testRequest;

@end

@implementation SPTDataLoaderServiceDefaultSessionSelectorTests

- (void)setUp
{
    [super setUp];

    self.testURL = [NSURL URLWithString:@"https://spotify.com"];
    self.operationQueue = [NSOperationQueue mainQueue];
    self.sessionDelegateMock = [NSURLSessionDelegateMock new];
    self.testRequest = [SPTDataLoaderRequest requestWithURL:self.testURL sourceIdentifier:nil];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.sessionSelector =
    [[SPTDataLoaderServiceDefaultSessionSelector alloc] initWithConfiguration:sessionConfiguration
                                                                     delegate:self.sessionDelegateMock
                                                                delegateQueue:self.operationQueue];
}

- (void)testNotNilSession
{
    NSURLSession *session = [self.sessionSelector URLSessionForRequest:self.testRequest];
    XCTAssertNotNil(session);
}

- (void)testSessionDelegateAndQueue
{
    NSURLSession *session = [self.sessionSelector URLSessionForRequest:self.testRequest];
    XCTAssertEqual(session.delegate, self.sessionDelegateMock);
    XCTAssertEqual(session.delegateQueue, self.operationQueue);
}

- (void)testSessionForBackgroundRequest
{
    NSURLSession *defaultSession = [self.sessionSelector URLSessionForRequest:self.testRequest];

    SPTDataLoaderRequest *backgroundRequest = [SPTDataLoaderRequest requestWithURL:self.testURL sourceIdentifier:nil];
    backgroundRequest.backgroundPolicy = SPTDataLoaderRequestBackgroundPolicyAlways;
    NSURLSession *backgroundSession = [self.sessionSelector URLSessionForRequest:backgroundRequest];

    // Should return a different session object for a background request.
    XCTAssertNotEqual(defaultSession, backgroundSession);
    // A background session object should have an identifier.
    XCTAssertNotNil(backgroundSession.configuration.identifier);
}

@end
