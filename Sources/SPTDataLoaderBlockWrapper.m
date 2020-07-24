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
#import "SPTDataLoaderBlockWrapper.h"
#import "SPTDataLoader.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const BlockRequestIdentifierKey = @"BlockRequestIdentifierKey";

@interface SPTDataLoaderBlockWrapper () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoader *dataLoader;

@end

@implementation SPTDataLoaderBlockWrapper

- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader
{
    self = [super init];
    if (self) {
        _dataLoader = dataLoader;
        dataLoader.delegate = self;
    }
    return self;
}

- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request completion:(SPTDataLoaderBlockCompletion)completion
{
    NSMutableDictionary *mutableUserInfo = [request.userInfo mutableCopy];
    if (mutableUserInfo == nil) {
        mutableUserInfo = [NSMutableDictionary new];
    }
    mutableUserInfo[BlockRequestIdentifierKey] = [completion copy];
    request.userInfo = mutableUserInfo;

    return [self.dataLoader performRequest:request];
}

- (void)dataLoader:(nonnull SPTDataLoader *)dataLoader didReceiveErrorResponse:(nonnull SPTDataLoaderResponse *)response
{
    SPTDataLoaderBlockCompletion completion = response.request.userInfo[BlockRequestIdentifierKey];
    if (completion != nil) {
        completion(response, nil);
    }
}

- (void)dataLoader:(nonnull SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(nonnull SPTDataLoaderResponse *)response
{
    SPTDataLoaderBlockCompletion completion = response.request.userInfo[BlockRequestIdentifierKey];
    if (completion != nil) {
        completion(response, response.error);
    }
}

@end

NS_ASSUME_NONNULL_END
