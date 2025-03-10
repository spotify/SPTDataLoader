/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderRequest.h>

@protocol SPTDataLoaderCancellationToken;

NS_ASSUME_NONNULL_BEGIN

/**
 A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderRequest (Private)

/**
 The URL request representing this request
 */
@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;
/**
 Whether the request has been retried with authorisation already
 @warning This is not copied when a copy is performed
 */
@property (nonatomic, assign) BOOL retriedAuthorisation;
/**
 The cancellation token associated with the request
 */
@property (nonatomic, weak) id<SPTDataLoaderCancellationToken> cancellationToken;

@end

NS_ASSUME_NONNULL_END
