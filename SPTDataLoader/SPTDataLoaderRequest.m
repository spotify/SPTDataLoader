#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

@implementation SPTDataLoaderRequest

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    NSString * const SPTDataLoaderRequestHostHeader = @"Host";
    NSString * const SPTDataLoaderRequestContentLengthHeader = @"Content-Length";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.URL];
    [urlRequest addValue:self.URL.host forHTTPHeaderField:SPTDataLoaderRequestHostHeader];
    
    if (self.body) {
        [urlRequest addValue:@(self.body.length).stringValue forHTTPHeaderField:SPTDataLoaderRequestContentLengthHeader];
        urlRequest.HTTPBody = self.body;
    }
    
    return urlRequest;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class new];
    copy.URL = self.URL;
    copy.retryCount = self.retryCount;
    copy.body = self.body;
    return copy;
}

@end
