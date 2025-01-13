/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderRequestResponseHandlerDelegate;
@protocol SPTDataLoaderAuthoriser;

NS_ASSUME_NONNULL_BEGIN

/**
 The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private) <SPTDataLoaderRequestResponseHandler>

/**
 Class constructor
 @param requestResponseHandlerDelegate The private delegate to delegate request handling to
 @param authorisers An NSArray of SPTDataLoaderAuthoriser objects for supporting different forms of authorisation
 */
+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(nullable id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(nullable NSArray<id<SPTDataLoaderAuthoriser>> *)authorisers;

@end

NS_ASSUME_NONNULL_END
