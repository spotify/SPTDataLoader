/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSBundleMock.h"

@implementation NSBundleMock

- (NSArray<NSString *> *)preferredLocalizations
{
    return self.mockPreferredLocalizations;
}

@end
