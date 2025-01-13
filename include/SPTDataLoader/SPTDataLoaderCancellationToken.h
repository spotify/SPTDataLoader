/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@protocol SPTDataLoaderCancellationToken;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol an object listening to the cancellation token must conform to
 */
@protocol SPTDataLoaderCancellationTokenDelegate <NSObject>

/**
 Called when the cancellation token becomes cancelled
 @param cancellationToken The cancellation token that became cancelled
 */
- (void)cancellationTokenDidCancel:(id<SPTDataLoaderCancellationToken>)cancellationToken;

@end

/**
 A cancellation token used for cancelling specific requests
 */
@protocol SPTDataLoaderCancellationToken <NSObject>

/**
 Whether the cancellation token has been cancelled
 */
@property (nonatomic, assign, readonly, getter = isCancelled) BOOL cancelled;
/**
 The object listening to the cancellation token
 @discussion This is immutable, the cancellation token should be fed this on its creation
 */
@property (nonatomic, weak, readonly, nullable) id<SPTDataLoaderCancellationTokenDelegate> delegate;
/**
 The object that will be affected by the cancellation
 */
@property (nonatomic, strong, readonly, nullable) id objectToCancel;

/**
 Cancels the cancellation token
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
