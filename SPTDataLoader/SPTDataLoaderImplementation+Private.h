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
#import "SPTDataLoaderImplementation.h"
#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderCancellationTokenFactory;

NS_ASSUME_NONNULL_BEGIN

/**
 The private API for the data loader for internal use in the SPTDataLoader library
 */
@interface SPTDataLoader (Private) <SPTDataLoaderRequestResponseHandler>

/**
 Class constructor
 @param requestResponseHandlerDelegate The private delegate for delegating the request handling
 @param cancellationTokenFactory The object used to create cancellation tokens
 */
+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                    cancellationTokenFactory:(id<SPTDataLoaderCancellationTokenFactory>)cancellationTokenFactory;

@end

NS_ASSUME_NONNULL_END
