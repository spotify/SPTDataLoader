#import "NSURLSessionDataTaskMock.h"

@implementation NSURLSessionDataTaskMock

@synthesize countOfBytesSent;
@synthesize countOfBytesReceived;
@synthesize currentRequest;
@synthesize response;

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

@end
