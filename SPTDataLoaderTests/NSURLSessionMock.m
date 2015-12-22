#import "NSURLSessionMock.h"
#import "NSURLSessionDataTaskMock.h"

@implementation NSURLSessionMock

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
{
    self.lastDataTask = [NSURLSessionDataTaskMock new];
    return self.lastDataTask;
}

@end
