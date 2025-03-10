/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderService.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPTDataLoaderServiceSessionSelector;


@interface SPTDataLoaderService ()

@property (nonatomic, strong) id<SPTDataLoaderServiceSessionSelector> sessionSelector;

@end

NS_ASSUME_NONNULL_END
