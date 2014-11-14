#import "NSURLSessionTaskMock.h"

@implementation NSURLSessionTaskMock

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    
}

@end
