/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <XCTest/XCTest.h>

#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolverAddress (Tests)

@property (nonatomic, assign) CFAbsoluteTime lastFailedTime;

@end

@interface SPTDataLoaderResolverAddressTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResolverAddress *address;

@end

@implementation SPTDataLoaderResolverAddressTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.address = [SPTDataLoaderResolverAddress dataLoaderResolverAddressWithAddress:@"192.168.0.1"];
}

#pragma mark SPTDataLoaderResolverAddressTest

- (void)testNotNil
{
    XCTAssertNotNil(self.address, @"The address should not be nil after construction");
}

- (void)testReachable
{
    XCTAssertTrue(self.address.reachable, @"The address should be reachable");
}

- (void)testNotReachableIfFailed
{
    [self.address failedToReach];
    XCTAssertFalse(self.address.reachable, @"The address should not be reachable");
}

- (void)testLastFailedTimeNonsensical
{
    self.address.lastFailedTime = CFAbsoluteTimeGetCurrent() + 100000;
    XCTAssertTrue(self.address.reachable, @"The address should be reachable");
}

@end
