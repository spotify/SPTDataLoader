/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@interface NSLocaleMock : NSLocale

+ (void)setPreferredLanguages:(NSArray<NSString *> *)languages;

@end
