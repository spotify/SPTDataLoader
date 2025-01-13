/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderRequestResponseHandlerMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfSuccessfulDataResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfReceivedInitialResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfNewBodyStreamCalls;
@property (nonatomic, strong, readwrite) SPTDataLoaderResponse *lastReceivedResponse;

@end

@implementation SPTDataLoaderRequestResponseHandlerMock

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfSuccessfulDataResponseCalls++;
    self.lastReceivedResponse = response;
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfFailedResponseCalls++;
    self.lastReceivedResponse = response;
    if (self.failedResponseBlock) {
        self.failedResponseBlock();
    }
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCancelledRequestCalls++;
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfReceivedDataRequestCalls++;
    self.lastReceivedResponse = response;
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfReceivedInitialResponseCalls++;
    self.lastReceivedResponse = response;
}

- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request
{
    return self.isAuthorising;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
}

- (void)requestIsWaitingForConnectivity:(nonnull SPTDataLoaderRequest *)request
{
}

- (void)needsNewBodyStream:(void (^)(NSInputStream * _Nonnull))completionHandler
                forRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfNewBodyStreamCalls++;
    completionHandler([[NSInputStream alloc] init]);
}

@end
