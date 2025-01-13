/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A category for calculating the size of a header represented by an NSDictionary
 */
@interface NSDictionary (HeaderSize)

/**
 The size of the header in bytes represented by the dictionary
 */
@property (nonatomic, assign, readonly, getter = spt_byteSizeOfHeaders) NSInteger byteSizeOfHeaders;

@end

NS_ASSUME_NONNULL_END
