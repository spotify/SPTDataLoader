/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
