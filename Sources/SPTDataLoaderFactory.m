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
#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import "SPTDataLoaderCancellationTokenFactoryImplementation.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderImplementation+Private.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderRequest+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandlerDelegate, SPTDataLoaderAuthoriserDelegate>

@property (nonatomic, strong) NSMapTable<SPTDataLoaderRequest *, id<SPTDataLoaderRequestResponseHandler>> *requestToRequestResponseHandler;
@property (nonatomic, strong, readwrite) dispatch_queue_t requestTimeoutQueue;

@end

@implementation SPTDataLoaderFactory

#pragma mark Private

+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(nullable id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(nullable NSArray<id<SPTDataLoaderAuthoriser>> *)authorisers
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate authorisers:authorisers];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(nullable id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                           authorisers:(nullable NSArray<id<SPTDataLoaderAuthoriser>> *)authorisers
{
    self = [super init];
    if (self) {
        _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
        _authorisers = [authorisers copy];

        _requestToRequestResponseHandler = [NSMapTable weakToWeakObjectsMapTable];
        _requestTimeoutQueue = dispatch_get_main_queue();

        for (id<SPTDataLoaderAuthoriser> authoriser in _authorisers) {
            authoriser.delegate = self;
        }
    }
    
    return self;
}

#pragma mark SPTDataLoaderFactory

- (SPTDataLoader *)createDataLoader
{
    id<SPTDataLoaderCancellationTokenFactory> cancellationTokenFactory = [SPTDataLoaderCancellationTokenFactoryImplementation new];
    return [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self
                                              cancellationTokenFactory:cancellationTokenFactory];
}

#pragma mark SPTDataLoaderRequestResponseHandler

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [self.requestToRequestResponseHandler removeObjectForKey:response.request];
    }
    [requestResponseHandler successfulResponse:response];
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    // If we failed on authorisation and we have not retried the authorisation, retry it
    if (response.error.code == SPTDataLoaderResponseHTTPStatusCodeUnauthorised && !response.request.retriedAuthorisation) {
        for (id<SPTDataLoaderAuthoriser> authoriser in self.authorisers) {
            if ([authoriser requestRequiresAuthorisation:response.request]) {
                [authoriser requestFailedAuthorisation:response.request];
            }
        }
        response.request.retriedAuthorisation = YES;
        if ([self shouldAuthoriseRequest:response.request]) {
            [self authoriseRequest:response.request];
            return;
        }
    }
    
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [self.requestToRequestResponseHandler removeObjectForKey:response.request];
    }
    [requestResponseHandler failedResponse:response];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:request];
        [self.requestToRequestResponseHandler removeObjectForKey:request];
    }
    [requestResponseHandler cancelledRequest:request];
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
    }
    [requestResponseHandler receivedDataChunk:data forResponse:response];
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
    }
    [requestResponseHandler receivedInitialResponse:response];
}

- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request
{
    for (id<SPTDataLoaderAuthoriser> authoriser in self.authorisers) {
        if ([authoriser requestRequiresAuthorisation:request]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    for (id<SPTDataLoaderAuthoriser> authoriser in self.authorisers) {
        if ([authoriser requestRequiresAuthorisation:request]) {
            [authoriser authoriseRequest:request];
            return;
        }
    }
}

- (void)needsNewBodyStream:(void (^)(NSInputStream * _Nonnull))completionHandler forRequest:(SPTDataLoaderRequest *)request
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = nil;
    @synchronized(self.requestToRequestResponseHandler) {
        requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:request];
    }
    [requestResponseHandler needsNewBodyStream:completionHandler forRequest:request];
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                performRequest:(SPTDataLoaderRequest *)request
{
    if (self.offline) {
        request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    }
    
    @synchronized(self.requestToRequestResponseHandler) {
        [self.requestToRequestResponseHandler setObject:requestResponseHandler forKey:request];
    }
    
    // Add an absolute timeout for responses
    if (request.timeout > 0.0) {
        __weak __typeof(self) weakSelf = self;
        __weak __typeof(request) weakRequest = request;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(request.timeout * NSEC_PER_SEC)),
                       self.requestTimeoutQueue,
                       ^{
                           __strong __typeof(self) strongSelf = weakSelf;
                           __strong __typeof(request) strongRequest = weakRequest;
                           SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:strongRequest
                                                                                                         response:nil];
                           NSError *error = [NSError errorWithDomain:SPTDataLoaderRequestErrorDomain
                                                                code:SPTDataLoaderRequestErrorCodeTimeout
                                                            userInfo:nil];
                           response.error = error;
                           [strongSelf failedResponse:response];
                       });
    }
    
    [self.requestResponseHandlerDelegate requestResponseHandler:self performRequest:request];
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 cancelRequest:(SPTDataLoaderRequest *)request
{
    [self.requestResponseHandlerDelegate requestResponseHandler:requestResponseHandler cancelRequest:request];
}

#pragma mark SPTDataLoaderAuthoriserDelegate

- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
           authorisedRequest:(SPTDataLoaderRequest *)request
{
    id<SPTDataLoaderRequestResponseHandlerDelegate> requestResponseHandlerDelegate = self.requestResponseHandlerDelegate;
    if ([requestResponseHandlerDelegate respondsToSelector:@selector(requestResponseHandler:authorisedRequest:)]) {
        [requestResponseHandlerDelegate requestResponseHandler:self authorisedRequest:request];
    }
}

- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
   didFailToAuthoriseRequest:(SPTDataLoaderRequest *)request
                   withError:(NSError *)error
{
    id<SPTDataLoaderRequestResponseHandlerDelegate> requestResponseHandlerDelegate = self.requestResponseHandlerDelegate;
    if ([requestResponseHandlerDelegate respondsToSelector:@selector(requestResponseHandler:failedToAuthoriseRequest:error:)]) {
        [requestResponseHandlerDelegate requestResponseHandler:self failedToAuthoriseRequest:request error:error];
    }
}

@end

NS_ASSUME_NONNULL_END
