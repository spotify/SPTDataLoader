/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The implementation for the cancellation token API
 */
@interface SPTDataLoaderCancellationTokenImplementation : NSObject <SPTDataLoaderCancellationToken>

/**
 Class constructor
 @param delegate The object listening to the cancellation token
 @param cancelObject The object that will be cancelled
 */
+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                               cancelObject:(nullable id)cancelObject;

@end

NS_ASSUME_NONNULL_END
