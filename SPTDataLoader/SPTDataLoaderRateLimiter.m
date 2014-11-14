#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>

#import "SPTDataLoaderRequest.h"

@interface SPTDataLoaderRateLimiter ()

@property (nonatomic, assign) double requestsPerSecond;

@property (nonatomic, strong) NSMutableDictionary *serviceEndpointRequestsPerSecond;
@property (nonatomic, strong) NSMutableDictionary *serviceEndpointLastExecution;
@property (nonatomic, strong) NSMutableDictionary *serviceEndpointRetryAt;

@end

@implementation SPTDataLoaderRateLimiter

#pragma mark SPTDataLoaderRateLimiter

+ (instancetype)rateLimiterWithDefaultRequestsPerSecond:(double)requestsPerSecond
{
    return [[self alloc] initWithDefaultRequestsPerSecond:requestsPerSecond];
}

- (instancetype)initWithDefaultRequestsPerSecond:(double)requestsPerSecond
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _requestsPerSecond = requestsPerSecond;
    _serviceEndpointRequestsPerSecond = [NSMutableDictionary new];
    _serviceEndpointLastExecution = [NSMutableDictionary new];
    _serviceEndpointRetryAt = [NSMutableDictionary new];
    
    return self;
}

- (NSTimeInterval)earliestTimeUntilRequestCanBeExecuted:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromURL:request.URL];
    
    // First check if we are not accepting requests until a certain time (i.e. Retry-after header)
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime retryAtTime = [self.serviceEndpointRetryAt[serviceKey] doubleValue];
    if (currentTime < retryAtTime) {
        return retryAtTime - currentTime;
    }
    
    // Next check that our rate limit is being respected
    double requestsPerSecond = [self requestsPerSecondForServiceKey:serviceKey];
    CFAbsoluteTime lastExecution = [self.serviceEndpointLastExecution[serviceKey] doubleValue];
    CFAbsoluteTime deltaTime = currentTime - lastExecution;
    CFAbsoluteTime cutoffTime = 1.0 / requestsPerSecond;
    CFAbsoluteTime timeInterval = cutoffTime - deltaTime;
    if (timeInterval < 0.0) {
        timeInterval = 0.0;
    }
    
    return timeInterval;
}

- (void)executedRequest:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromURL:request.URL];
    if (!serviceKey) {
        return;
    }
    
    self.serviceEndpointLastExecution[serviceKey] = @(CFAbsoluteTimeGetCurrent());
}

- (double)requestsPerSecondForURL:(NSURL *)URL
{
    return [self requestsPerSecondForServiceKey:[self serviceKeyFromURL:URL]];
}

- (void)setRequestsPerSecond:(double)requestsPerSecond forURL:(NSURL *)URL
{
    self.serviceEndpointRequestsPerSecond[[self serviceKeyFromURL:URL]] = @(requestsPerSecond);
}

- (void)setRetryAfter:(NSTimeInterval)absoluteTime forURL:(NSURL *)URL
{
    if (!URL) {
        return;
    }
    
    self.serviceEndpointRetryAt[[self serviceKeyFromURL:URL]] = @(absoluteTime);
}

- (double)requestsPerSecondForServiceKey:(NSString *)serviceKey
{
    return [self.serviceEndpointRequestsPerSecond[serviceKey] doubleValue] ?: self.requestsPerSecond;
}

- (NSString *)serviceKeyFromURL:(NSURL *)URL
{
    if (!URL) {
        return nil;
    }
    
    NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    NSURLComponents *serviceComponents = [NSURLComponents new];
    serviceComponents.scheme = requestComponents.scheme;
    serviceComponents.host = requestComponents.host;
    serviceComponents.path = requestComponents.path.pathComponents.firstObject;
    NSString *serviceKey = serviceComponents.URL.absoluteString;
    return serviceKey;
}

@end
