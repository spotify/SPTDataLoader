/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderTimeProviderImplementation.h"

@implementation SPTDataLoaderTimeProviderImplementation

- (CFAbsoluteTime)currentTime
{
    return CFAbsoluteTimeGetCurrent();
}

@end
