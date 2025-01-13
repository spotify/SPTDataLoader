/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>

@protocol SPTDataLoaderTimeProvider;

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderRateLimiter (Private)

- (instancetype)initWithDefaultRequestsPerSecond:(double)requestsPerSecond
                                    timeProvider:(id<SPTDataLoaderTimeProvider>)timeProvider;

@property (nonatomic, strong, readonly) id<SPTDataLoaderTimeProvider> timeProvider;

@end

NS_ASSUME_NONNULL_END
