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

@class SPTDataLoaderService;

NS_ASSUME_NONNULL_BEGIN

@protocol SPTDataLoaderServiceEventObserver <NSObject>

/**
 Called when the underlying background URL session notifies about finishing background events.
 
 @discussion This method will only be called if a background session is used to handle some of the requests. To achieve
 that, set the request background policy to @c SPTDataLoaderRequestBackgroundPolicyAlways and configure the service to
 work in background.
 */
- (void)dataLoaderServiceDidFinishBackgroundEvents:(SPTDataLoaderService *)dataLoaderService __OSX_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
