/*
 Copyright (c) 2015-2020 Spotify AB.

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

NS_ASSUME_NONNULL_BEGIN

@class SPTDataLoaderRequest;


/**
 A @c SPTDataLoaderServiceSessionSelector is responsible for selecting the most appropriate @c NSURLSession for a
 given request.
 */
@protocol SPTDataLoaderServiceSessionSelector <NSObject>

- (NSURLSession *)URLSessionForRequest:(SPTDataLoaderRequest *)request;
- (void)invalidateAndCancel;
@end

/**
 Production implementation of @c SPTDataLoaderServiceSessionSelector .
 */
@interface SPTDataLoaderServiceDefaultSessionSelector: NSObject <SPTDataLoaderServiceSessionSelector>

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                             delegate:(id<NSURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)delegateQueue;

/**
 Initialize a new selector object and enable background networking.

 @param configuration A configuration used to create URL session for foreground work.
 @param backgroundConfiguration A configuration for a background URL session used for background tasks.
 @param delegate The delegate to receive URL session updates.
 @param delegateQueue The queue to receive delegate updates in.

 @discussion This method will create a background URL session which will be returned for all requests with background
 policy value set to @c SPTDataLoaderRequestBackgroundPolicyAlways.
 */
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
              backgroundConfiguration:(NSURLSessionConfiguration *)backgroundConfiguration
                             delegate:(id<NSURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)delegateQueue;

@end

NS_ASSUME_NONNULL_END
