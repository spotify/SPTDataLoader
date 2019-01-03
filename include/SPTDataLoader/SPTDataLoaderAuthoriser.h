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

@protocol SPTDataLoaderAuthoriser;

NS_ASSUME_NONNULL_BEGIN

@protocol SPTDataLoaderAuthoriserDelegate <NSObject>

/**
 Called when the data loader authoriser successfully authorises a request
 @param dataLoaderAuthoriser The object authorising the request
 @param request The request that has been successfully authorised
 */
- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
           authorisedRequest:(SPTDataLoaderRequest *)request;
/**
 Called when the data loader fails to authorise a request
 @param dataLoaderAuthoriser The object that failed to authorise the request
 @param request The request that has failed to become authorised
 @param error The error describing the failure
 */
- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
   didFailToAuthoriseRequest:(SPTDataLoaderRequest *)request
                   withError:(NSError *)error;

@end

/**
 An object that could act as an authoriser for injecting the required authorisation headers into a request
 */
@protocol SPTDataLoaderAuthoriser <NSObject, NSCopying>

/**
 The identifier for the data loader authoriser
 @discussion This should be unique for each type of authorisation
 */
@property (nonatomic, strong, readonly) NSString *identifier;
/**
 The object listening to the authoriser
 */
@property (nonatomic, weak, nullable) id<SPTDataLoaderAuthoriserDelegate> delegate;

/**
 Whether a request requires authorisation from this authoriser
 @param request The request to check
 */
- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request;
/**
 Authorise a request
 @param request The request to authorise
 @discussion This will invoke one of the delegate methods in response
 */
- (void)authoriseRequest:(SPTDataLoaderRequest *)request;
/**
 Mark that a request failed authorisation
 @param request The request to authorise
 */
- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request;
/**
 Refreshes any kind authorisation
 @discussion This is never called by the factory, it is expected that the authoriser will be able to handle refreshes
 when the requestFailedAuthorisation: is called. This is for the benefit of outside consumers of this API.
 */
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
