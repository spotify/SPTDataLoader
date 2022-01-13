/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
