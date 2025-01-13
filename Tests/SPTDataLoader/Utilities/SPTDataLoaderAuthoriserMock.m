/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderAuthoriserMock.h"

@interface SPTDataLoaderAuthoriserMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToAuthoriseRequest;

@end

@implementation SPTDataLoaderAuthoriserMock

@synthesize identifier = _identifier;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enabled = YES;
    }
    return self;
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    return self.enabled;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCallsToAuthoriseRequest++;
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request response:(SPTDataLoaderResponse *)response
{
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self.class new];
}

- (void)refresh
{

}

@end
