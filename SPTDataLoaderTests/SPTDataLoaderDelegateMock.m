/*
 Copyright (c) 2015-2018 Spotify AB.

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
#import "SPTDataLoaderDelegateMock.h"

@implementation SPTDataLoaderDelegateMock

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(dataLoader:needsNewBodyStream:forRequest:)) {
        return self.respondsToBodyStreamPrompts;
    } else {
        return [super respondsToSelector:aSelector];
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfCallsToSuccessfulResponse++;
    if (self.receivedSuccessfulBlock) {
        self.receivedSuccessfulBlock();
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfCallsToErrorResponse++;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCallsToCancelledRequest++;
}

- (BOOL)dataLoaderShouldSupportChunks:(SPTDataLoader *)dataLoader
{
    return self.supportChunks;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader
didReceiveDataChunk:(NSData *)data
       forResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfCallsToReceiveDataChunk++;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveInitialResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfCallsToReceivedInitialResponse++;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader needsNewBodyStream:(void (^)(NSInputStream * _Nonnull))completionHandler forRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCallsToNeedNewBodyStream++;
}

@end
