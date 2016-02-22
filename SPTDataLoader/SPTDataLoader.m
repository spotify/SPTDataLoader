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
#import "SPTDataLoader+Private.h"

#import "SPTDataLoaderRequest.h"
#import "SPTDataLoaderResponse.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderDelegate.h"
#import "SPTDataLoaderResponse+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoader ()

@property (nonatomic, strong) NSHashTable<id<SPTDataLoaderCancellationToken>> *cancellationTokens;
@property (nonatomic, strong) NSMutableArray<SPTDataLoaderRequest *> *requests;

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
    if (self.delegateQueue == dispatch_get_main_queue() && [NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(self.delegateQueue, block);
    }
}

#pragma mark SPTDataLoader

- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    SPTDataLoaderRequest *copiedRequest = [request copy];
    id<SPTDataLoaderDelegate> delegate = self.delegate;

    // Cancel the request immediately if it requires chunks and the delegate does not support that
    BOOL chunksSupported = [delegate respondsToSelector:@selector(dataLoaderShouldSupportChunks:)];
    if (chunksSupported) {
        chunksSupported = [delegate dataLoaderShouldSupportChunks:self];
    }
    if (!chunksSupported && copiedRequest.chunks) {
        NSError *error = [NSError errorWithDomain:SPTDataLoaderRequestErrorDomain
                                             code:SPTDataLoaderRequestErrorChunkedRequestWithoutChunkedDelegate
                                         userInfo:nil];
        SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
        response.error = error;
        [delegate dataLoader:self didReceiveErrorResponse:response];
        return nil;
    }

    id<SPTDataLoaderCancellationToken> cancellationToken = [self.requestResponseHandlerDelegate requestResponseHandler:self
                                                                                                        performRequest:copiedRequest];
    @synchronized(self.cancellationTokens) {
        [self.cancellationTokens addObject:cancellationToken];
    }
    
    @synchronized(self.requests) {
        [self.requests addObject:copiedRequest];
    }
    
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
    @synchronized(self.requests) {
        [self.requests removeObject:response.request];
    }
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveErrorResponse:response];
    }];
    @synchronized(self.requests) {
        [self.requests removeObject:response.request];
    }
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:didCancelRequest:)]) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didCancelRequest:request];
        }];
    }
    @synchronized(self.requests) {
        [self.requests removeObject:request];
    }
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

NS_ASSUME_NONNULL_END
