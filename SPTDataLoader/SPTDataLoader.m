#import "SPTDataLoader.h"

#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderRequest.h"

@interface SPTDataLoader ()

@property (nonatomic, strong) NSHashTable *cancellationTokens;

@end

@implementation SPTDataLoader

#pragma mark Private

+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
    
    _cancellationTokens = [NSHashTable weakObjectsHashTable];
    
    return self;
}

#pragma mark SPTDataLoader

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    SPTDataLoaderRequest *copiedRequest = [request copy];
    
    if ([self.delegate respondsToSelector:@selector(dataLoaderShouldSupportChunks:)]) {
        BOOL chunkSupport = [self.delegate dataLoaderShouldSupportChunks:self];
        if (!chunkSupport) {
            copiedRequest.chunks = NO;
        }
    }
    
    id<SPTCancellationToken> cancellationToken = [self.requestResponseHandlerDelegate requestResponseHandler:self
                                                                                              performRequest:copiedRequest];
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

#pragma mark SPTDataLoaderRequestResponseHandler

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

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

- (void)receivedDataChunk:(NSData *)data forRequest:(SPTDataLoaderRequest *)request
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:didReceiveDataChunk:forRequest:)]) {
        [self.delegate dataLoader:self didReceiveDataChunk:data forRequest:request];
    }
}

@end
