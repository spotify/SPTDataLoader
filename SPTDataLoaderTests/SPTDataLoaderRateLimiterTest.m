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
@import XCTest;

#import "SPTDataLoaderRateLimiter.h"

#import "SPTDataLoaderRequest.h"

@interface SPTDataLoaderRateLimiterTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, assign) double requestsPerSecond;

@end

@implementation SPTDataLoaderRateLimiterTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.requestsPerSecond = 10.0;
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:self.requestsPerSecond];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRateLimiterTest

- (void)testNotNil
{
    XCTAssertNotNil(self.rateLimiter, @"The rate limiter should not be nil after construction");
}

- (void)testEarliestTimeUntilRequestCanBeRealisedWithRetryAfter
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    NSTimeInterval seconds = 60.0;
    CFAbsoluteTime retryAfter = CFAbsoluteTimeGetCurrent() + seconds;
    [self.rateLimiter setRetryAfter:retryAfter forURL:URL];
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, seconds, 1.0, @"The retry-after limitation was not respected by the rate limiter");
}

- (void)testEarliestTimeUntilRequestCanBeRealised
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    [self.rateLimiter executedRequest:request];
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    NSString *earliestTimeWithDecimalPrecision = [NSString stringWithFormat:@"%0.1f", earliestTime];
    XCTAssertEqualObjects(earliestTimeWithDecimalPrecision, @"0.1", @"The requests per second limitation was not respected by the rate limiter");
}

- (void)testExecutedRequestWithNilRequest
{
    // Test no crash
    [self.rateLimiter executedRequest:nil];
}

- (void)testRequestsPerSecondDefault
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    double requestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    XCTAssertEqualWithAccuracy(requestsPerSecond, self.requestsPerSecond, 1.0, @"The requests per second for a URL is not falling back to the default specified in the class constructor");
}

- (void)testRequestsPerSecondCustom
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    double requestsPerSecond = 20.0;
    [self.rateLimiter setRequestsPerSecond:requestsPerSecond forURL:URL];
    double reportedRequestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    XCTAssertEqualWithAccuracy(requestsPerSecond, reportedRequestsPerSecond, 1.0, @"The requests per second for this URL was not what was explicitly set");
}

- (void)testSetRetryAfterWithNilURL
{
    // Test no crash
    [self.rateLimiter setRetryAfter:60.0 forURL:nil];
}

- (void)testResetRetryAfterAfterSuccessfulExecution
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    NSTimeInterval seconds = 60.0;
    CFAbsoluteTime retryAfter = CFAbsoluteTimeGetCurrent() + seconds;
    [self.rateLimiter setRetryAfter:retryAfter forURL:URL];
    [self.rateLimiter executedRequest:request];
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, 0.0, 1.0, @"The earliest time until request can be executed was not reset despite an overwrite of the retry-after rule");
}

@end
