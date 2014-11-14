#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandlerDelegate, SPTDataLoaderAuthoriserDelegate>

@property (nonatomic, copy) NSArray *authorisers;

@property (nonatomic, strong) NSMapTable *requestToRequestResponseHandler;

@end

@implementation SPTDataLoaderFactory

#pragma mark Private

+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(NSArray *)authorisers
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate authorisers:authorisers];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                           authorisers:(NSArray *)authorisers
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
    _authorisers = [authorisers copy];
    
    _requestToRequestResponseHandler = [NSMapTable weakToWeakObjectsMapTable];
    
    for (id<SPTDataLoaderAuthoriser> authoriser in _authorisers) {
        authoriser.delegate = self;
    }
    
    return self;
}

#pragma mark SPTDataLoaderFactory

- (SPTDataLoader *)createDataLoader
{
    return [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self];
}

#pragma mark SPTDataLoaderRequestResponseHandler

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self) {
        id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [requestResponseHandler successfulResponse:response];
    }
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self) {
        id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [requestResponseHandler failedResponse:response];
    }
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    @synchronized(self) {
        id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:request];
        [requestResponseHandler cancelledRequest:request];
    }
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self) {
        id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [requestResponseHandler receivedDataChunk:data forResponse:response];
    }
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self) {
        id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
        [requestResponseHandler receivedInitialResponse:response];
    }
}

- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request
{
    for (id<SPTDataLoaderAuthoriser> authoriser in self.authorisers) {
        if ([authoriser requestRequiresAuthorisation:request]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    for (id<SPTDataLoaderAuthoriser> authoriser in self.authorisers) {
        if ([authoriser requestRequiresAuthorisation:request]) {
            [authoriser authoriseRequest:request];
            return;
        }
    }
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    if (self.offline) {
        request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    }
    
    @synchronized(self) {
        [self.requestToRequestResponseHandler setObject:requestResponseHandler forKey:request];
    }
    
    return [self.requestResponseHandlerDelegate requestResponseHandler:self performRequest:request];
}

#pragma mark SPTDataLoaderAuthoriserDelegate

- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
           authorisedRequest:(SPTDataLoaderRequest *)request
{
    if ([self.requestResponseHandlerDelegate respondsToSelector:@selector(requestResponseHandler:authorisedRequest:)]) {
        [self.requestResponseHandlerDelegate requestResponseHandler:self authorisedRequest:request];
    }
}

- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
   didFailToAuthoriseRequest:(SPTDataLoaderRequest *)request
                   withError:(NSError *)error
{
    if ([self.requestResponseHandlerDelegate respondsToSelector:@selector(requestResponseHandler:failedToAuthoriseRequest:error:)]) {
        [self.requestResponseHandlerDelegate requestResponseHandler:self failedToAuthoriseRequest:request error:error];
    }
}

@end
