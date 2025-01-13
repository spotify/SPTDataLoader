/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderServerTrustPolicyMock.h"

@implementation SPTDataLoaderServerTrustPolicyMock

- (BOOL)validateChallenge:(NSURLAuthenticationChallenge *)challenge
{
    return self.shouldBeTrusted;
}

@end
