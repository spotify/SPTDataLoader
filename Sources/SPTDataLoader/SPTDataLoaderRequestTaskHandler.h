/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@class SPTDataLoaderRequestTaskHandler;
@class SPTDataLoaderRequest;
@class SPTDataLoaderRateLimiter;
@class SPTDataLoaderResponse;

@protocol SPTDataLoaderRequestResponseHandler;

NS_ASSUME_NONNULL_BEGIN

@protocol SPTDataLoaderRequestTaskHandlerDelegate <NSObject>

/**
 Called when the existing task has completed and a new one is required in order to retry the request.
 @param requestTaskHandler The object handling the request task
 */
- (void)requestTaskHandlerNeedsNewTask:(SPTDataLoaderRequestTaskHandler *)requestTaskHandler;

@end

/**
 The handler for performing a URL session task and forwarding the requests to relevant request response handler
 */
@interface SPTDataLoaderRequestTaskHandler : NSObject

/**
 The task for performing the URL request on
 */
@property (atomic, strong) NSURLSessionTask *task;
/**
 The request response handler to callback to
 */
@property (nonatomic, strong) SPTDataLoaderRequest *request;
/**
 Whether the request was cancelled
 */
@property (nonatomic, assign, readonly, getter = isCancelled) BOOL cancelled;

/**
 Class constructor
 @param task The task to perform
 @param request The request object to perform lookup with
 @param requestResponseHandler The object tie to this operation for potential callbacks
 @param rateLimiter The object controlling the rate limits on a per service basis
 @param delegate The object listening to the task handler
 */
+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                            delegate:(id<SPTDataLoaderRequestTaskHandlerDelegate>)delegate;

/**
 Call to tell the operation it has received a response
 @param response The object describing the response it received from the server
 */
- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response;
/**
 Call to tell the operation it has received some data
 @param data The data from the URL session performing the task
 */
- (void)receiveData:(NSData *)data;
/**
 Tell the operation the URL session has completed the request
 @param error An optional error to use if the request was not completed successfully
 @return The response object unless the request was cancelled or will be re-tried in which case `nil` is returned.
 */
- (nullable SPTDataLoaderResponse *)completeWithError:(nullable NSError *)error;
/**
 Called when a request with waitsForConnectivity enters the waiting state
*/
- (void)noteWaitingForConnectivity;
/**
 Gets called whenever the original request was redirected.
 Returns YES to allow redirect, NO to block it.
 */
- (BOOL)mayRedirect;
/**
 Start the data loader task associated with the request
 */
- (void)start;

/**
 Provides the task with a new body input stream.
 */
- (void)provideNewBodyStreamWithCompletion:(void (^)(NSInputStream * _Nonnull))completionHandler;

@end

NS_ASSUME_NONNULL_END
