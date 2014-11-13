#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderRequestResponseHandlerMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readwrite) NSUInteger numberOfSuccessfulDataResponseCalls;

@end

@implementation SPTDataLoaderRequestResponseHandlerMock

@synthesize requestResponseHandlerDelegate = _requestResponseHandlerDelegate;

- (void)successfulResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfSuccessfulDataResponseCalls++;
}

- (void)failedResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfFailedResponseCalls++;
}

- (void)cancelledRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCancelledRequestCalls++;
}

- (void)receivedDataChunk:(NSData *)data forResponse:(SPTDataLoaderResponse *)response
{
    self.numberOfReceivedDataRequestCalls++;
}

- (void)receivedInitialResponse:(SPTDataLoaderResponse *)response
{
    
}

@end
