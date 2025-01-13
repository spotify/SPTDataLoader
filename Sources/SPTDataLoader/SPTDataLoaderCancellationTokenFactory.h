/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@protocol SPTDataLoaderCancellationToken;
@protocol SPTDataLoaderCancellationTokenDelegate;

/**
 A factory for creating generic cancellation tokens
 */
@protocol SPTDataLoaderCancellationTokenFactory <NSObject>

/**
 Create a cancellation token
 @param delegate The object listening to the cancellation token
 @param cancelObject The object related to the cancel function
 */
- (id<SPTDataLoaderCancellationToken>)createCancellationTokenWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                                             cancelObject:(id)cancelObject;

@end
