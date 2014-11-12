#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

NSString * const SPTDataLoaderRequestHostHeader = @"Host";

@interface SPTDataLoaderRequest ()

@property (nonatomic, strong) NSMutableDictionary *mutableHeaders;

@end

@implementation SPTDataLoaderRequest

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    NSString * const SPTDataLoaderRequestContentLengthHeader = @"Content-Length";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.URL];
    [urlRequest addValue:self.URL.host forHTTPHeaderField:SPTDataLoaderRequestHostHeader];
    
    if (self.body) {
        [urlRequest addValue:@(self.body.length).stringValue forHTTPHeaderField:SPTDataLoaderRequestContentLengthHeader];
        urlRequest.HTTPBody = self.body;
    }
    
    for (NSString *key in self.headers) {
        NSString *value = self.headers[key];
        [urlRequest addValue:value forHTTPHeaderField:key];
    }
    
    return urlRequest;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class new];
    copy.URL = [self.URL copy];
    copy.retryCount = self.retryCount;
    copy.body = [self.body copy];
    copy.mutableHeaders = [self.mutableHeaders mutableCopy];
    return copy;
}

#pragma mark SPTDataLoaderRequest

- (NSDictionary *)headers
{
    return [self.mutableHeaders copy];
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    self.mutableHeaders[header] = value;
}

- (void)removeHeader:(NSString *)header
{
    [self.mutableHeaders removeObjectForKey:header];
}

#pragma mark NSObject

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _mutableHeaders = [NSMutableDictionary new];
    
    return self;
}

@end
