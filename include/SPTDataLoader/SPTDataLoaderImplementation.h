/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@protocol SPTDataLoaderCancellationToken;
@protocol SPTDataLoaderDelegate;
@class SPTDataLoaderRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 The object used for performing requests
 */
@interface SPTDataLoader : NSObject

#pragma mark Delegating Tasks

/**
 The object listening to the data loader.
 */
@property (nonatomic, weak, nullable) id<SPTDataLoaderDelegate> delegate;
/**
 The queue to call the delegate selectors on.
 @discussion By default this is the main queue.
 */
@property (nonatomic, strong) dispatch_queue_t delegateQueue;
/**
 The requests currently under flight in the data loader
 */
@property (nonatomic, copy, readonly) NSArray<SPTDataLoaderRequest *> *currentRequests;

#pragma mark Performing Requests

/**
 Performs a request and returns a cancellation token associated with it.
 @discussion If the request can’t be performed `nil` will be returned and the receiver’s delegate will be sent the
 `dataLoader:didReceiveErrorResponse:`. The response object sent to the delegate will contain an `NSError` object
 describing what went wrong.
 @param request The object describing the kind of request to be performed
 @return A cancellation token associated with the request, or `nil` if the request coulnd’t be performed.
 */
- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request;

#pragma mark Cancelling Loads

/**
 Cancels all the currently operating and pending requests
 */
- (void)cancelAllLoads;

@end

NS_ASSUME_NONNULL_END
