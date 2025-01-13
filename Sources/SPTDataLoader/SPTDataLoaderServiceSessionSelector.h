/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SPTDataLoaderRequest;


/**
 A @c SPTDataLoaderServiceSessionSelector is responsible for selecting the most appropriate @c NSURLSession for a
 given request.
 */
@protocol SPTDataLoaderServiceSessionSelector <NSObject>

- (NSURLSession *)URLSessionForRequest:(SPTDataLoaderRequest *)request;
- (void)invalidateAndCancel;
@end

/**
 Production implementation of @c SPTDataLoaderServiceSessionSelector .
 */
@interface SPTDataLoaderServiceDefaultSessionSelector: NSObject <SPTDataLoaderServiceSessionSelector>

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                             delegate:(id<NSURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)delegateQueue;

@end

NS_ASSUME_NONNULL_END
