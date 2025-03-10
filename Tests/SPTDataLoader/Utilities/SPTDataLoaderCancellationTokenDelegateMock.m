/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderCancellationTokenDelegateMock.h"

@implementation SPTDataLoaderCancellationTokenDelegateMock

- (void)cancellationTokenDidCancel:(id<SPTDataLoaderCancellationToken>)cancellationToken
{
    self.numberOfCallsToCancellationTokenDidCancel++;
}

@end
