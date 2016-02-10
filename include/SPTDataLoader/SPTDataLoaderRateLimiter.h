/*
 * Copyright (c) 2015-2016 Spotify AB.
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

@class SPTDataLoaderRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 * A rate limiter for configuring custom rates on a per service basis
 * @discussion A service is defined as the scheme, host and first path component of the URL
 */
@interface SPTDataLoaderRateLimiter : NSObject

/**
 * Class constructor
 * @param requestsPerSecond The number of requests per second as a default to allow for a service
 */
+ (instancetype)rateLimiterWithDefaultRequestsPerSecond:(double)requestsPerSecond;

/**
 * Finds the earliest time until a request can be executed
 * @param request The request pending for execution
 * @discussion A result of 0.0 means the request can be executed immediately
 */
- (NSTimeInterval)earliestTimeUntilRequestCanBeExecuted:(SPTDataLoaderRequest *)request;
/**
 * Tells the rate limiter a request is currently being executed
 * @param request The request being executed
 */
- (void)executedRequest:(SPTDataLoaderRequest *)request;
/**
 * The amount of requests per second that are allowed to be executed on a URL
 * @param URL The URL to check the requests per second for
 */
- (double)requestsPerSecondForURL:(NSURL *)URL;
/**
 * Set the requests per second that are allowed to be executed on a URL
 * @param requestsPerSecond The number of requests per second to accept
 * @param URL The URL to check the requests per second for
 */
- (void)setRequestsPerSecond:(double)requestsPerSecond forURL:(NSURL *)URL;
/**
 * Set the amount of time to wait until retrying for a given URL
 * @param absoluteTime The time when the retry after can be realised
 * @param URL The URL to set the retry after
 */
- (void)setRetryAfter:(NSTimeInterval)absoluteTime forURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
