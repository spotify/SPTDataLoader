#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

@implementation SPTDataLoaderRequest

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    return [NSURLRequest requestWithURL:self.URL];
}

@end
