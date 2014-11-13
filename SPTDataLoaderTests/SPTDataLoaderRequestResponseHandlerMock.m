#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderRequestResponseHandlerMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfFailedResponseCalls;

@end

@implementation SPTDataLoaderRequestResponseHandlerMock

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfFailedResponseCalls++;
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    
}

- (void)receivedDataChunk:(NSData *)data forRequest:(SPTDataLoaderRequest *)request
{
    
}

@end
