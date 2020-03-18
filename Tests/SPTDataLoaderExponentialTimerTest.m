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

#import <SPTDataLoader/SPTDataLoader.h>

@interface SPTDataLoaderExponentialTimerTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderExponentialTimer *timer;

@end

@implementation SPTDataLoaderExponentialTimerTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.timer = [SPTDataLoaderExponentialTimer exponentialTimerWithInitialTime:1.0 maxTime:10.0];
}

#pragma mark SPTDataLoaderExponentialTimerTest

- (void)testReset
{
    NSTimeInterval currentTimerInterval = 0.0;
    for (int i = 0; i < 3; ++i) {
        currentTimerInterval = [self.timer timeIntervalAndCalculateNext];
    }
    XCTAssertGreaterThan(currentTimerInterval, 0.0);
    [self.timer reset];
    XCTAssertEqualWithAccuracy(self.timer.timeInterval, 1.0, DBL_EPSILON);
}

- (void)testInitialTimeOfZeroResultsInZeroAlways
{
    self.timer = [SPTDataLoaderExponentialTimer exponentialTimerWithInitialTime:0.0 maxTime:10.0 jitter:0.0];
    NSTimeInterval currentTimerInterval = 0.0;
    for (int i = 0; i < 10; ++i) {
        currentTimerInterval = [self.timer timeIntervalAndCalculateNext];
    }
    XCTAssertEqualWithAccuracy(currentTimerInterval, 0.0, DBL_EPSILON);
}

- (void)testMaxTimeReached
{
    NSTimeInterval currentTimerInterval = 0.0;
    for (int i = 0; i < 100; ++i) {
        currentTimerInterval = [self.timer timeIntervalAndCalculateNext];
    }
    XCTAssertLessThanOrEqual(currentTimerInterval, 10.0);
}

@end
