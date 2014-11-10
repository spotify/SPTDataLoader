#import "SPTDataLoader.h"

#import "SPTDataLoader+Private.h"

@interface SPTDataLoader ()

@property (nonatomic, weak) id<SPTDataLoaderPrivateDelegate> privateDelegate;
@property (nonatomic, strong) NSHashTable *cancellationTokens;

@end

@implementation SPTDataLoader

#pragma mark Private

+ (instancetype)dataLoaderWithPrivateDelegate:(id<SPTDataLoaderPrivateDelegate>)privateDelegate
{
    return [[self alloc] initWithPrivateDelegate:privateDelegate];
}

- (instancetype)initWithPrivateDelegate:(id<SPTDataLoaderPrivateDelegate>)privateDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _privateDelegate = privateDelegate;
    
    _cancellationTokens = [NSHashTable weakObjectsHashTable];
    
    return self;
}

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

- (void)dealloc
{
    [self cancelAllLoads];
}

@end
