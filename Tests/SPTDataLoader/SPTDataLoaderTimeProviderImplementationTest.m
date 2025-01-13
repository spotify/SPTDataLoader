/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <XCTest/XCTest.h>
#import "SPTDataLoaderTimeProviderImplementation.h"

@interface SPTDataLoaderTimeProviderImplementationTest: XCTestCase

@end

@implementation SPTDataLoaderTimeProviderImplementationTest

- (void)testCurrentTimeIsEqualToCFAbsoluteTimeGetCurrent
{
    // Given
    const CFAbsoluteTime expectedTime = CFAbsoluteTimeGetCurrent();
    SPTDataLoaderTimeProviderImplementation *timeProvider = [SPTDataLoaderTimeProviderImplementation new];

    // When
    const CFAbsoluteTime actualTime = timeProvider.currentTime;

    // Time
    XCTAssertEqualWithAccuracy(expectedTime, actualTime, 0.1, @"The currentTime is not equal to the system time given by CFAbsoluteTimeGetCurrent()");
}

@end
