#import "NSURLSessionTaskMock.h"

@implementation NSURLSessionTaskMock

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

@end
