#import "SPTDataLoaderFactory.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoader+Private.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandler, SPTDataLoaderRequestResponseHandlerDelegate>
@end

@implementation SPTDataLoaderFactory

#pragma mark Private

+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    return [[self alloc] initWithRequestResponseHandlerDelegate:requestResponseHandlerDelegate];
}

- (instancetype)initWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _requestResponseHandlerDelegate = requestResponseHandlerDelegate;
    
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
    
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    return [self.requestResponseHandlerDelegate requestResponseHandler:self performRequest:request];
}

@end
