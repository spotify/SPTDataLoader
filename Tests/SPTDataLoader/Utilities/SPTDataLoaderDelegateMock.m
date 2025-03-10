/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
    completionHandler([[NSInputStream alloc] init]);
}

@end
