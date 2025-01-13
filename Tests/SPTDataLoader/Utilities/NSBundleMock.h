/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@interface NSBundleMock : NSBundle

@property (readwrite, copy, atomic) NSArray<NSString *> *mockPreferredLocalizations;

@end
