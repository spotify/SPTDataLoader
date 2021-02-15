/*
 Copyright (c) 2015-2021 Spotify AB.

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

@class SPTDataLoader;
@class SPTDataLoaderBlockWrapper;
@protocol SPTDataLoaderAuthoriser;

NS_ASSUME_NONNULL_BEGIN

/**
 A factory for producing data loaders and automatically authorising requests
 */
@interface SPTDataLoaderFactory : NSObject

/**
 Whether the factory is simulating being offline
 @discussion This forces all requests to only use local caching and never reach a remote server
 */
@property (nonatomic, assign, getter = isOffline) BOOL offline;
/**
 The objects authorising HTTP requests for this factory
 @discussion The NSArray consists of objects conforming to the SPTDataLoaderAuthoriser protocol
 */
@property (nonatomic, copy, readonly, nullable) NSArray<id<SPTDataLoaderAuthoriser>> *authorisers;

/**
 Creates a data loader
 */
- (SPTDataLoader *)createDataLoader;

/**
 Creates a data loader with a block API
 */
- (SPTDataLoaderBlockWrapper *)createDataLoaderBlockWrapper;

@end

NS_ASSUME_NONNULL_END
