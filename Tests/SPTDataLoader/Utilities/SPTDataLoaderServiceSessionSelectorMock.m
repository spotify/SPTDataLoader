/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderServiceSessionSelectorMock.h"
#import "NSURLSessionMock.h"

@interface SPTDataLoaderServiceSessionSelectorMock ()

@property (nonatomic, strong, readonly) NSURLSession *(^resolve)(SPTDataLoaderRequest *);

@end


@implementation SPTDataLoaderServiceSessionSelectorMock

- (instancetype)initWithResolver:(NSURLSession *(^)(SPTDataLoaderRequest *))resolver
{
    self = [super init];

    if (self != nil) {
        _resolve = resolver;
    }

    return self;
}

- (NSURLSession *)URLSessionForRequest:(SPTDataLoaderRequest *)request
{
    return self.resolve(request);
}

- (void)invalidateAndCancel
{
}

@end
