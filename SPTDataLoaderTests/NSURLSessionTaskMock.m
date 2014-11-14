#import "NSURLSessionTaskMock.h"

@implementation NSURLSessionTaskMock

- (void)resume
{
    self.numberOfCallsToResume++;
}

@end
