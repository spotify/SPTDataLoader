/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@class SPTDataLoader;
@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;
@protocol SPTDataLoaderCancellationToken;

typedef void (^SPTDataLoaderBlockCompletion)(SPTDataLoaderResponse * _Nonnull response, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

/**
 A wrapper providing a block interface for the common use case of SPTDataLoader
 */
@interface SPTDataLoaderBlockWrapper : NSObject

/// Initialises a data loader block wrapper
/// @param dataLoader An SPTDataLoader object
- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader;


/// Performs a request and returns a cancellation token associated with it.
/// @param request The object describing the kind of request to be performed
/// @param completion A completion block with the response and an error object
/// @return A cancellation token associated with the request, or `nil` if the request coulnd’t be performed.
- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
                                                   completion:(SPTDataLoaderBlockCompletion)completion;

@end

NS_ASSUME_NONNULL_END
