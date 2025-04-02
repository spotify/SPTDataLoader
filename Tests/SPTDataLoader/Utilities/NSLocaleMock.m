/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSLocaleMock.h"

@implementation NSLocaleMock

static NSArray<NSString *> *_mockPreferredLanguages;

+ (NSArray<NSString *> *)preferredLanguages {
    return _mockPreferredLanguages;
}

+ (void)setPreferredLanguages:(NSArray<NSString *> *)languages
{
    _mockPreferredLanguages = languages;
}

@end
