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

#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The implementation for the cancellation token API
 */
@interface SPTDataLoaderCancellationTokenImplementation : NSObject <SPTDataLoaderCancellationToken>

/**
 Class constructor
 @param delegate The object listening to the cancellation token
 @param cancelObject The object that will be cancelled
 */
+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                               cancelObject:(nullable id)cancelObject;

@end

NS_ASSUME_NONNULL_END
