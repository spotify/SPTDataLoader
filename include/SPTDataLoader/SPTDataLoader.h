/*
 * Copyright (c) 2015 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import <Foundation/Foundation.h>

// Because of its name, let this header double as a convenience header
#import <SPTDataLoader/SPTCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>
#import <SPTDataLoader/SPTDataLoaderFactory.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTExpTime.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>

/**
 * The protocol used for listening to the result of performing requests on the SPTDataLoader
 * @discussion One of the following callbacks are guaranteed to happen for every request being track by the data loader:
 * - didReceiveSuccessfulResponse
 * - didReceiveErrorResponse
 * - didCancelRequest
 */
@protocol SPTDataLoaderDelegate <NSObject>

/**
 * Called when the data loader received a successful response
 * @param dataLoader The data loader that received the successful response
 * @param response The object describing the response
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader received an error response
 * @param dataLoader The data loader that received the error response
 * @param response The object describing the response
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader cancels a request
 * @param dataLoader The data loader that cancelled the request
 * @param request The object describing the request that was cancelled
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request;

@optional

/**
 * Whether the data loader delegate will support chunks being called back
 * @param dataLoader The data loader asking the delegate for its support
 */
- (BOOL)dataLoaderShouldSupportChunks:(SPTDataLoader *)dataLoader;
/**
 * Called when the data loader receives a chunk of data for a request
 * @param dataLoader The data loader that receives the chunk
 * @param data The data that the data loader received
 * @param response The response that generated the data
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader
didReceiveDataChunk:(NSData *)data
        forResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader receives an initial response for a request
 * @param dataLoader The data loader that received the initial response
 * @param response The response with all values filled out other than its body
 * @discussion This is guaranteed to be called before the first call of dataLoader:didReceiveDataChunk:forResponse
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveInitialResponse:(SPTDataLoaderResponse *)response;

@end

/**
 * The object used for performing requests
 */
@interface SPTDataLoader : NSObject

/**
 * The object listening to the data loader
 */
@property (nonatomic, weak) id<SPTDataLoaderDelegate> delegate;
/**
 * The queue to call the delegate selectors on
 * @discussion By default this is the main queue
 */
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

/**
 * Performs a request
 * @param request The object describing the kind of request to be performed
 */
- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request;
/**
 * Cancels all the currently operating and pending requests
 */
- (void)cancelAllLoads;

@end
