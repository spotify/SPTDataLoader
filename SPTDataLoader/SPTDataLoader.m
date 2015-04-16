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
#import <SPTDataLoader/SPTDataLoader.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>

#import "SPTDataLoader+Private.h"

@interface SPTDataLoader ()

@property (nonatomic, strong) NSHashTable *cancellationTokens;
@property (nonatomic, strong) NSMutableArray *requests;

@end

@implementation SPTDataLoader

#pragma mark Private

+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
    
    _cancellationTokens = [NSHashTable weakObjectsHashTable];
    _delegateQueue = dispatch_get_main_queue();
    _requests = [NSMutableArray new];
    
    return self;
}

- (void)executeDelegateBlock:(dispatch_block_t)block
{
    if (!block) {
        return;
    }
    
    if (self.delegateQueue == dispatch_get_main_queue() && [NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(self.delegateQueue, block);
    }
}

#pragma mark SPTDataLoader

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    SPTDataLoaderRequest *copiedRequest = [request copy];
    if ([self.delegate respondsToSelector:@selector(dataLoaderShouldSupportChunks:)] && copiedRequest.chunks) {
        NSAssert([self.delegate dataLoaderShouldSupportChunks:self], @"The data loader was given a request that required chunks while the delegate does not support chunks");
    }
    id<SPTCancellationToken> cancellationToken = [self.requestResponseHandlerDelegate requestResponseHandler:self
                                                                                              performRequest:copiedRequest];
    @synchronized(self.cancellationTokens) {
        [self.cancellationTokens addObject:cancellationToken];
    }
    
    [self.requests addObject:copiedRequest];
    
    return cancellationToken;
}

- (void)cancelAllLoads
{
    NSArray *cancellationTokens = nil;
    @synchronized(self.cancellationTokens) {
        cancellationTokens = [self.cancellationTokens.allObjects copy];
        [self.cancellationTokens removeAllObjects];
    }
    [cancellationTokens makeObjectsPerformSelector:@selector(cancel)];
}

#pragma mark NSObject

- (void)dealloc
{
    [self cancelAllLoads];
}

#pragma mark SPTDataLoaderRequestResponseHandler

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveSuccessfulResponse:response];
    }];
    [self.requests removeObject:response.request];
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveErrorResponse:response];
    }];
    [self.requests removeObject:response.request];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didCancelRequest:request];
    }];
    [self.requests removeObject:request];
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    // Do not send a callback if the request doesn't support it
    NSAssert(response.request.chunks, @"The data loader is receiving a data chunk for a response that doesn't support data chunks");
    
    BOOL didReceiveDataChunkSelectorExists = [self.delegate respondsToSelector:@selector(dataLoader:didReceiveDataChunk:forResponse:)];
    if (didReceiveDataChunkSelectorExists) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didReceiveDataChunk:data forResponse:response];
        }];
    }
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    // Do not send a callback if the request doesn't support it
    if (!response.request.chunks) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(dataLoader:didReceiveInitialResponse:)]) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didReceiveInitialResponse:response];
        }];
    }
}

@end
