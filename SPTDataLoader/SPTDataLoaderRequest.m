#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequest+Private.h"

NSString * const SPTDataLoaderRequestHostHeader = @"Host";

@interface SPTDataLoaderRequest ()

@property (nonatomic, strong) NSMutableDictionary *mutableHeaders;
@property (nonatomic, strong) id<SPTCancellationToken> cancellationToken;

@end

@implementation SPTDataLoaderRequest

#pragma mark SPTDataLoaderRequest

+ (instancetype)requestWithURL:(NSURL *)URL
{
    return [[self alloc] initWithURL:URL];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _URL = URL;
    
    _mutableHeaders = [NSMutableDictionary new];
    
    return self;
}

- (NSDictionary *)headers
{
    return [self.mutableHeaders copy];
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    if (!header) {
        return;
    }
    
    if (!value && header) {
        [self.mutableHeaders removeObjectForKey:header];
        return;
    }
    
    self.mutableHeaders[header] = value;
}

- (void)removeHeader:(NSString *)header
{
    [self.mutableHeaders removeObjectForKey:header];
}

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    NSString * const SPTDataLoaderRequestContentLengthHeader = @"Content-Length";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.URL];
    
    if (!self.headers[SPTDataLoaderRequestHostHeader]) {
        [urlRequest addValue:self.URL.host forHTTPHeaderField:SPTDataLoaderRequestHostHeader];
    }
    
    if (self.body) {
        [urlRequest addValue:@(self.body.length).stringValue forHTTPHeaderField:SPTDataLoaderRequestContentLengthHeader];
        urlRequest.HTTPBody = self.body;
    }
    
    for (NSString *key in self.headers) {
        NSString *value = self.headers[key];
        [urlRequest addValue:value forHTTPHeaderField:key];
    }
    
    urlRequest.cachePolicy = self.cachePolicy;
    
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
    copy.chunks = self.chunks;
    copy.cachePolicy = self.cachePolicy;
    return copy;
}

@end
