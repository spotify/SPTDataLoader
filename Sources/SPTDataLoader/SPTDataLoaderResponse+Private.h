/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderResponse.h>

@class SPTDataLoaderRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderResponse (Private)

/**
 The error that the request generated
 */
@property (nonatomic, strong, readwrite, nullable) NSError *error;
/**
 Allows private consumers to alter the data for the response
 */
@property (nonatomic, strong, readwrite, nullable) NSData *body;
/**
 Allows private consumers to alter the request time for the response
 */
@property (nonatomic, assign, readwrite) NSTimeInterval requestTime;

/**
 Class constructor
 @param request The request object making up the response
 @param response The URL response received from the session
 */
+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request response:(nullable NSURLResponse *)response;

/**
 Whether we should retry the current request based on the current response data
 */
- (BOOL)shouldRetry;

@end

NS_ASSUME_NONNULL_END
