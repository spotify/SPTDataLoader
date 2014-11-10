#import "SPTDataLoader.h"

#import "SPTDataLoader+Private.h"

@interface SPTDataLoader ()

@property (nonatomic, weak) id<SPTDataLoaderPrivateDelegate> privateDelegate;
@property (nonatomic, strong) NSHashTable *cancellationTokens;

@end

@implementation SPTDataLoader

#pragma mark SPTDataLoader

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    id<SPTCancellationToken> cancellationToken = [self.privateDelegate performRequest:request];
    [self.cancellationTokens addObject:cancellationToken];
    return cancellationToken;
}

- (void)cancelAllLoads
{
    NSArray *cancellationTokens = self.cancellationTokens.allObjects;
    [cancellationTokens makeObjectsPerformSelector:@selector(cancel)];
}

#pragma mark NSObject

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _cancellationTokens = [NSHashTable weakObjectsHashTable];
    
    return self;
}

#pragma mark Private

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    [self.delegate dataLoader:self didReceiveSuccessfulResponse:response];
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    [self.delegate dataLoader:self didReceiveErrorResponse:response];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    [self.delegate dataLoader:self didCancelRequest:request];
}

@end
