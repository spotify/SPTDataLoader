#import "NSURLSessionMock.h"

@implementation NSURLSessionMock

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
{
    self.lastDataTask = [NSURLSessionDataTask new];
    return self.lastDataTask;
}

@end
