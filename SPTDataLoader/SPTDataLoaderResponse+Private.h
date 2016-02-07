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
#import "SPTDataLoaderResponse.h"

@class SPTDataLoaderRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderResponse (Private)

/**
 * The error that the request generated
 */
@property (nonatomic, strong, readwrite, nullable) NSError *error;
/**
 * Allows private consumers to alter the data for the response
 */
@property (nonatomic, strong, readwrite, nullable) NSData *body;
/**
 * Allows private consumers to alter the request time for the response
 */
@property (nonatomic, assign, readwrite) NSTimeInterval requestTime;

/**
 * Class constructor
 * @param request The request object making up the response
 * @param response The URL response received from the session
 */
+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request response:(nullable NSURLResponse *)response;

/**
 * Whether we should retry the current request based on the current response data
 */
- (BOOL)shouldRetry;

@end

NS_ASSUME_NONNULL_END
