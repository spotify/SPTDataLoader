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
#import "SPTDataLoaderImplementation+Private.h"

#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderDelegate.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>

#import "SPTDataLoaderCancellationTokenFactoryImplementation.h"
#import "SPTDataLoaderRequest+Private.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoader () <SPTDataLoaderCancellationTokenDelegate>

@property (nonatomic, strong, readonly) NSMutableArray<id<SPTDataLoaderCancellationToken>> *cancellationTokens;
@property (nonatomic, strong, readonly) NSMutableArray<SPTDataLoaderRequest *> *requests;
@property (nonatomic, strong, readonly) id<SPTDataLoaderCancellationTokenFactory> cancellationTokenFactory;

@end

@implementation SPTDataLoader

#pragma mark Private

+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                    cancellationTokenFactory:(nonnull id<SPTDataLoaderCancellationTokenFactory>)cancellationTokenFactory
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate
                                       cancellationTokenFactory:cancellationTokenFactory];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                              cancellationTokenFactory:(id<SPTDataLoaderCancellationTokenFactory>)cancellationTokenFactory
{
    self = [super init];
    if (self) {
        _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
        _cancellationTokenFactory = cancellationTokenFactory;

        _cancellationTokens = [NSMutableArray new];
        _delegateQueue = dispatch_get_main_queue();
        _requests = [NSMutableArray new];
    }
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

- (void)removeRequest:(SPTDataLoaderRequest *)request
{
    @synchronized(self.requests) {
        [self.requests removeObject:request];
    }

    @synchronized(self.cancellationTokens) {
        NSMutableIndexSet *indicesToRemove = [NSMutableIndexSet new];
        for (NSUInteger i = 0; i < self.cancellationTokens.count; i++) {
            if ([self.cancellationTokens[i].objectToCancel isEqual:request]) {
                [indicesToRemove addIndex:i];
            }
        }
        [self.cancellationTokens removeObjectsAtIndexes:indicesToRemove];
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

    id<SPTDataLoaderCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:self
                                                                                                                 cancelObject:copiedRequest];
    copiedRequest.cancellationToken = cancellationToken;
    @synchronized(self.cancellationTokens) {
        [self.cancellationTokens addObject:cancellationToken];
    }
    
    @synchronized(self.requests) {
        [self.requests addObject:copiedRequest];
    }

    [self.requestResponseHandlerDelegate requestResponseHandler:self performRequest:copiedRequest];
    
    return cancellationToken;
}

- (void)cancelAllLoads
{
    NSArray *cancellationTokens = nil;
    @synchronized(self.cancellationTokens) {
        cancellationTokens = [self.cancellationTokens copy];
        [self.cancellationTokens removeAllObjects];
    }
    [cancellationTokens makeObjectsPerformSelector:@selector(cancel)];
}

- (BOOL)isRequestExpected:(SPTDataLoaderRequest *)request
{
    @synchronized (self.requests) {
        for (SPTDataLoaderRequest *expectedRequest in self.requests) {
            if (request.uniqueIdentifier == expectedRequest.uniqueIdentifier) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray<SPTDataLoaderRequest *> *)currentRequests
{
    @synchronized (self.requests) {
        return [self.requests copy];
    }
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
    if (![self isRequestExpected:response.request]) {
        return;
    }
    
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveSuccessfulResponse:response];
    }];

    [self removeRequest:response.request];
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    if (![self isRequestExpected:response.request]) {
        return;
    }

    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveErrorResponse:response];
    }];

    [self removeRequest:response.request];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    if (![self isRequestExpected:request]) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(dataLoader:didCancelRequest:)]) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didCancelRequest:request];
        }];
    }

    [self removeRequest:request];
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    if (![self isRequestExpected:response.request]) {
        return;
    }

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
    if (![self isRequestExpected:response.request]) {
        return;
    }

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

- (void)requestIsWaitingForConnectivity:(SPTDataLoaderRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:requestIsWaitingForConnectivity:)]) {
        [self executeDelegateBlock:^{
            [self.delegate dataLoader:self requestIsWaitingForConnectivity:request];
        }];
    }
}

- (void)needsNewBodyStream:(void (^)(NSInputStream *))completionHandler
                forRequest:(SPTDataLoaderRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:needsNewBodyStream:forRequest:)]) {
        [self executeDelegateBlock:^{
            [self.delegate dataLoader:self
                   needsNewBodyStream:completionHandler
                           forRequest:request];
        }];
    } else {
        completionHandler(request.bodyStream);
    }
}

#pragma mark SPTDataLoaderCancellationTokenDelegate

- (void)cancellationTokenDidCancel:(id<SPTDataLoaderCancellationToken>)cancellationToken
{
    SPTDataLoaderRequest *request = (SPTDataLoaderRequest *)cancellationToken.objectToCancel;
    [self.requestResponseHandlerDelegate requestResponseHandler:self cancelRequest:request];
    [self cancelledRequest:request];
}

@end

NS_ASSUME_NONNULL_END
