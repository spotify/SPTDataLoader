/*
 Copyright (c) 2015-2019 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import <Foundation/Foundation.h>

@protocol SPTDataLoaderCancellationToken;
@protocol SPTDataLoaderDelegate;
@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;

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

/**
 An alternative performRequest method that takes in a response handler and invokes the handler when the request is complete.
 This enables a single data loader object to be reused by multiple objects that don't need to implement the delegat protocol
 and can all submit requests.
 @discussion The completion handler will be invoked only for terminal states, i.e. when a request succeeded or failed,
 or when it was canceled.  If the request was cancelled, the reponse parameter of the completion handler will be nil.
 On success or failure the reponse will be not nil and the completion handler must examine the response in order to
 determine whether the request succeeded or failed.
 */
- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
                                               withCompletion:(void (^)(SPTDataLoaderResponse *response))completion;

#pragma mark Cancelling Loads

/**
 Cancels all the currently operating and pending requests
 */
- (void)cancelAllLoads;

@end

NS_ASSUME_NONNULL_END
