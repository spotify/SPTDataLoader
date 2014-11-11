#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

@implementation SPTDataLoaderRequest

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    return [NSURLRequest requestWithURL:self.URL];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class new];
    copy.URL = self.URL;
    copy.retryCount = self.retryCount;
    return copy;
}

@end
