#import "SPTDataLoaderDelegateMock.h"

@implementation SPTDataLoaderDelegateMock

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfCallsToSuccessfulResponse++;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    
}

- (BOOL)dataLoaderShouldSupportChunks:(SPTDataLoader *)dataLoader
{
    return self.supportChunks;
}

- (void)dataLoader:(SPTDataLoader *)dataLoader
didReceiveDataChunk:(NSData *)data
       forResponse:(SPTDataLoaderResponse *)response
{
    
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveInitialResponse:(SPTDataLoaderResponse *)response
{
    
}

@end
