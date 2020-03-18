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

#import "SPTDataLoaderServiceSessionSelector.h"
#import <SPTDataLoader/SPTDataLoaderRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderServiceDefaultSessionSelector ()

@property (nonatomic, strong, readonly) NSURLSessionConfiguration *configuration;
@property (nonatomic, weak, readonly) id<NSURLSessionDelegate> delegate;
@property (nonatomic, strong, readonly) NSOperationQueue *delegateQueue;

@end


@implementation SPTDataLoaderServiceDefaultSessionSelector
{
    NSURLSession *_nonWaitingSession;
    NSURLSession *_waitingSession;
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                             delegate:(id<NSURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)delegateQueue
{
    self = [super init];

    if (self != nil) {
        _configuration = [configuration copy];
        _delegate = delegate;
        _delegateQueue = delegateQueue;
    }

    return self;
}

- (NSURLSession *)URLSessionForRequest:(SPTDataLoaderRequest *)request
{
    if (request.waitsForConnectivity) {
        return self.waitingSession;
    } else {
        return self.nonWaitingSession;
    }
}

- (NSURLSession *)waitingSession
{
    if (_waitingSession == nil) {
        _waitingSession = [self createWaitingSession];
    }
    return _waitingSession;
}

- (NSURLSession *)nonWaitingSession
{
    if (_nonWaitingSession == nil) {
        _nonWaitingSession = [NSURLSession sessionWithConfiguration:self.configuration
                                                           delegate:self.delegate
                                                      delegateQueue:self.delegateQueue];
    }
    return _nonWaitingSession;
}

- (NSURLSession *)createWaitingSession
{
    if (@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)) {
        NSURLSessionConfiguration *configuration = [self.configuration copy];
        configuration.waitsForConnectivity = YES;
        return [NSURLSession sessionWithConfiguration:configuration
                                             delegate:self.delegate
                                        delegateQueue:self.delegateQueue];
    } else {
        return self.nonWaitingSession;
    }
}

- (void)invalidateAndCancel
{
    [self.waitingSession invalidateAndCancel];
    [self.nonWaitingSession invalidateAndCancel];
}

@end

NS_ASSUME_NONNULL_END
