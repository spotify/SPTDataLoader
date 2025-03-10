/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
