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

@class SPTDataLoaderRequest;
@class SPTDataLoaderRateLimiter;
@class SPTDataLoaderResponse;
@protocol SPTDataLoaderRequestResponseHandler;

/**
 * The handler for performing a URL session task and forwarding the requests to relevant request response handler
 */
@interface SPTDataLoaderRequestTaskHandler : NSObject

/**
 * The task for performing the URL request on
 */
@property (nonatomic, strong) NSURLSessionTask *task;
/**
 * The request response handler to callback to
 */
@property (nonatomic, strong) SPTDataLoaderRequest *request;

/**
 * Class constructor
 * @param request The request object to perform lookup with
 * @param task The task to perform
 * @param requestResponseHandler The object tie to this operation for potential callbacks
 * @param rateLimiter The object controlling the rate limits on a per service basis
 */
+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter;

/**
 * Call to tell the operation it has received a response
 * @param response The object describing the response it received from the server
 */
- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response;
/**
 * Call to tell the operation it has received some data
 * @param data The data from the URL session performing the task
 */
- (void)receiveData:(NSData *)data;
/**
 * Tell the operation the URL session has completed the request
 * @param error An optional error to use if the request was not completed successfully
 */
- (SPTDataLoaderResponse *)completeWithError:(NSError *)error;
/**
 * Gets called whenever the original request was redirected.
 * Returns YES to allow redirect, NO to block it.
 */
- (BOOL)mayRedirect;
/**
 * Start the data loader task associated with the request
 */
- (void)start;

@end
