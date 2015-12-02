#import "NSURLSessionDataTaskMock.h"

@implementation NSURLSessionDataTaskMock

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

@end
