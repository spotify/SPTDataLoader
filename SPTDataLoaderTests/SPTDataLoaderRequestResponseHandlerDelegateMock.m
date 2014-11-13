#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"

@implementation SPTDataLoaderRequestResponseHandlerDelegateMock

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    self.lastRequestPerformed = request;
    
    if (self.tokenCreator) {
        return self.tokenCreator();
    }
    
    return nil;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
             authorisedRequest:(SPTDataLoaderRequest *)request
{
    self.lastRequestAuthorised = request;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
      failedToAuthoriseRequest:(SPTDataLoaderRequest *)request
                         error:(NSError *)error
{
    self.lastRequestFailed = request;
}

@end
