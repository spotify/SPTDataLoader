/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
