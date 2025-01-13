/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderImplementation.h>
#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderCancellationTokenFactory;

NS_ASSUME_NONNULL_BEGIN

/**
 The private API for the data loader for internal use in the SPTDataLoader library
 */
@interface SPTDataLoader (Private) <SPTDataLoaderRequestResponseHandler>

/**
 Class constructor
 @param requestResponseHandlerDelegate The private delegate for delegating the request handling
 @param cancellationTokenFactory The object used to create cancellation tokens
 */
+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                    cancellationTokenFactory:(id<SPTDataLoaderCancellationTokenFactory>)cancellationTokenFactory;

@end

NS_ASSUME_NONNULL_END
