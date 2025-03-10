/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <XCTest/XCTest.h>

#import "SPTDataLoaderCancellationTokenFactoryImplementation.h"

#import "SPTDataLoaderCancellationTokenDelegateMock.h"

@interface SPTDataLoaderCancellationTokenFactoryImplementationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderCancellationTokenFactoryImplementation *cancellationTokenFactory;

@end

@implementation SPTDataLoaderCancellationTokenFactoryImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.cancellationTokenFactory = [SPTDataLoaderCancellationTokenFactoryImplementation new];
}

#pragma mark SPTCancellationTokenFactoryImplementationTest

- (void)testCreateCancellationToken
{
    id<SPTDataLoaderCancellationTokenDelegate> delegate = [SPTDataLoaderCancellationTokenDelegateMock new];
    id<SPTDataLoaderCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:delegate cancelObject:nil];
    XCTAssertNotNil(cancellationToken, @"The factory did not provide a valid cancellation token");
    id<SPTDataLoaderCancellationTokenDelegate> cancellationTokenDelegate = cancellationToken.delegate;
    XCTAssertEqual(delegate, cancellationTokenDelegate, @"The factory did not set the delegate on the cancellation token");
}

@end
