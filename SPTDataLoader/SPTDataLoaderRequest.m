#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequest+Private.h"

NSString * const SPTDataLoaderRequestHostHeader = @"Host";

static NSString * const NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod);

@interface SPTDataLoaderRequest ()

@property (nonatomic, strong) NSMutableDictionary *mutableHeaders;
@property (nonatomic, strong) id<SPTCancellationToken> cancellationToken;
@property (nonatomic, assign) BOOL retriedAuthorisation;

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
    _method = SPTDataLoaderRequestMethodGet;
    
    return self;
}

- (NSDictionary *)headers
{
    @synchronized(self) {
        return [self.mutableHeaders copy];
    }
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    if (!header) {
        return;
    }
    
    @synchronized(self) {
        if (!value && header) {
            [self.mutableHeaders removeObjectForKey:header];
            return;
        }
        
        self.mutableHeaders[header] = value;
    }
}

- (void)removeHeader:(NSString *)header
{
    @synchronized(self) {
        [self.mutableHeaders removeObjectForKey:header];
    }
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
    
    NSDictionary *headers = self.headers;
    for (NSString *key in headers) {
        NSString *value = headers[key];
        [urlRequest addValue:value forHTTPHeaderField:key];
    }
    
    urlRequest.cachePolicy = self.cachePolicy;
    urlRequest.HTTPMethod = NSStringFromSPTDataLoaderRequestMethod(self.method);
    
    return urlRequest;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class requestWithURL:self.URL];
    copy.retryCount = self.retryCount;
    copy.body = [self.body copy];
    @synchronized(self) {
        copy.mutableHeaders = [self.mutableHeaders mutableCopy];
    }
    copy.chunks = self.chunks;
    copy.cachePolicy = self.cachePolicy;
    copy.method = self.method;
    return copy;
}

@end

static NSString * const SPTDataLoaderRequestDeleteMethodString = @"DELETE";
static NSString * const SPTDataLoaderRequestGetMethodString = @"GET";
static NSString * const SPTDataLoaderRequestPostMethodString = @"POST";
static NSString * const SPTDataLoaderRequestPutMethodString = @"PUT";

static NSString * const NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod)
{
    switch (requestMethod) {
        case SPTDataLoaderRequestMethodDelete: return SPTDataLoaderRequestDeleteMethodString;
        case SPTDataLoaderRequestMethodGet: return SPTDataLoaderRequestGetMethodString;
        case SPTDataLoaderRequestMethodPost: return SPTDataLoaderRequestPostMethodString;
        case SPTDataLoaderRequestMethodPut: return SPTDataLoaderRequestPutMethodString;
    }
}
