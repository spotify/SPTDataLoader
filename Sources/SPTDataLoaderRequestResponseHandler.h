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

@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;

@protocol SPTDataLoaderRequestResponseHandler;

NS_ASSUME_NONNULL_BEGIN

/**
 A private delegate API for the creator of SPTDataLoader to use for routing requests through a user authentication
 layer
 */
@protocol SPTDataLoaderRequestResponseHandlerDelegate <NSObject>

/**
 Performs a request
 @param requestResponseHandler The object that can perform requests and responses
 @param request The object describing the request to perform
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                performRequest:(SPTDataLoaderRequest *)request;
/**
 Cancels a request
 @param requestResponseHandler The object that can perform cancels
 @param request The object describing the request to cancel
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 cancelRequest:(SPTDataLoaderRequest *)request;

@optional

/**
 Delegate a successfully authorised request
 @param requestResponseHandler The handler that successfully authorised the request
 @param request The request that contains the authorisation headers
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
             authorisedRequest:(SPTDataLoaderRequest *)request;
/**
 Delegate a failed authorisation attempt for a request
 @param requestResponseHandler The handler that failed to authorise the request
 @param request The request whose authorisation failed
 @param error The object describing the failure in the authorisation request
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
      failedToAuthoriseRequest:(SPTDataLoaderRequest *)request
                         error:(NSError *)error;

@end

@protocol SPTDataLoaderRequestResponseHandler <NSObject>

/**
 The object to delegate performing requests to
 */
@property (nonatomic, weak, readonly, nullable) id<SPTDataLoaderRequestResponseHandlerDelegate> requestResponseHandlerDelegate;

/**
 Call when a response successfully completed
 @param response The response that successfully completed
 */
- (void)successfulResponse:(SPTDataLoaderResponse *)response;
/**
 Call when a response failed to complete
 @param response The response that failed to complete
 */
- (void)failedResponse:(SPTDataLoaderResponse *)response;
/**
 Call when a request becomes cancelled
 @param request The request that was cancelled
 */
- (void)cancelledRequest:(SPTDataLoaderRequest *)request;
/**
 Called when a chunk is received
 @param data The data received by the request
 @param response The response the chunk is received for
 */
- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response;
/**
 Called when the headers for a response are received
 @param response The response containing the initial information (such as headers)
 */
- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response;

- (void)requestIsWaitingForConnectivity:(SPTDataLoaderRequest *)request;

/**
 Called when a request using the @c bodyStream property encounters some sort of redirection that invalidates
 the initially provided input stream.
 @param completionHandler The completion handler that is to be called with the new input stream.
 @param request The request that needs a new input stream.
 */
- (void)needsNewBodyStream:(void (^)(NSInputStream *))completionHandler
                forRequest:(SPTDataLoaderRequest *)request;

@optional

/**
 Whether the request needs authorisation according to this handler
 @param request The request that may need authorisation
 */
- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request;
/**
 Authorise a request
 @param request The request to be authorise
 */
- (void)authoriseRequest:(SPTDataLoaderRequest *)request;

@end

NS_ASSUME_NONNULL_END
