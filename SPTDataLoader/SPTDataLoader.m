#import <SPTDataLoader/SPTDataLoader.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoader+Private.h"

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
    @synchronized(self) {
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
}

- (void)cancelAllLoads
{
    @synchronized(self) {
        NSArray *cancellationTokens = [self.cancellationTokens.allObjects copy];
        [cancellationTokens makeObjectsPerformSelector:@selector(cancel)];
    }
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

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    BOOL didReceiveDataChunkSelectorExists = [self.delegate respondsToSelector:@selector(dataLoader:didReceiveDataChunk:forResponse:)];
    NSAssert(didReceiveDataChunkSelectorExists, @"The SPTDataLoaderDelegate does not implement didReceiveDataChunk yet received a data chunk back");
    if (didReceiveDataChunkSelectorExists) {
        [self.delegate dataLoader:self didReceiveDataChunk:data forResponse:response];
    }
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:didReceiveInitialResponse:)]) {
        [self.delegate dataLoader:self didReceiveInitialResponse:response];
    }
}

@end
