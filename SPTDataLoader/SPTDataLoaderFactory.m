#import "SPTDataLoaderFactory.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderResponse.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandler, SPTDataLoaderRequestResponseHandlerDelegate>

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
    _authorisers = authorisers;
    
    _requestToRequestResponseHandler = [NSMapTable weakToWeakObjectsMapTable];
    
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
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
    [requestResponseHandler successfulResponse:response];
    
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:response.request];
    [requestResponseHandler failedResponse:response];
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    id<SPTDataLoaderRequestResponseHandler> requestResponseHandler = [self.requestToRequestResponseHandler objectForKey:request];
    [requestResponseHandler cancelledRequest:request];
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    [self.requestToRequestResponseHandler setObject:requestResponseHandler forKey:request];
    return [self.requestResponseHandlerDelegate requestResponseHandler:self performRequest:request];
}

@end
