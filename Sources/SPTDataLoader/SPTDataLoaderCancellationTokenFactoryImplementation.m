/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderCancellationTokenFactoryImplementation.h"

#import "SPTDataLoaderCancellationTokenImplementation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPTDataLoaderCancellationTokenFactoryImplementation

#pragma mark SPTDataLoaderCancellationTokenFactory

- (id<SPTDataLoaderCancellationToken>)createCancellationTokenWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                                             cancelObject:(id)cancelObject
{
    return [SPTDataLoaderCancellationTokenImplementation cancellationTokenImplementationWithDelegate:delegate
                                                                                        cancelObject:cancelObject];
}

@end

NS_ASSUME_NONNULL_END
