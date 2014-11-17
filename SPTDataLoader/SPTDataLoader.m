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
    _delegateQueue = dispatch_get_main_queue();
    
    return self;
}

- (void)executeDelegateBlock:(dispatch_block_t)block
{
    if (!block) {
        return;
    }
    
    if (self.delegateQueue == dispatch_get_main_queue() && [NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(self.delegateQueue, block);
    }
}

#pragma mark SPTDataLoader

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    @synchronized(self) {
        SPTDataLoaderRequest *copiedRequest = [request copy];
        
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
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveSuccessfulResponse:response];
    }];
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didReceiveErrorResponse:response];
    }];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    [self executeDelegateBlock: ^{
        [self.delegate dataLoader:self didCancelRequest:request];
    }];
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    BOOL didReceiveDataChunkSelectorExists = [self.delegate respondsToSelector:@selector(dataLoader:didReceiveDataChunk:forResponse:)];
    if (didReceiveDataChunkSelectorExists) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didReceiveDataChunk:data forResponse:response];
        }];
    }
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    if ([self.delegate respondsToSelector:@selector(dataLoader:didReceiveInitialResponse:)]) {
        [self executeDelegateBlock: ^{
            [self.delegate dataLoader:self didReceiveInitialResponse:response];
        }];
    }
}

@end
