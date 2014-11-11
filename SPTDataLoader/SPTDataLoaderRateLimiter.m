#import "SPTDataLoaderRateLimiter.h"

#import "SPTDataLoaderRequest.h"

@interface SPTDataLoaderRateLimiter ()

@property (nonatomic, assign) double requestsPerSecond;

@property (nonatomic, strong) NSMutableDictionary *serviceEndpointRequestsPerSecond;
@property (nonatomic, strong) NSMutableDictionary *serviceEndpointLastExecution;

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
    
    return self;
}

- (NSTimeInterval)earliestTimeUntilRequestCanBeExecuted:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromRequest:request];
    
    double requestsPerSecond = [self requestsPerSecondForServiceKey:serviceKey];
    CFAbsoluteTime lastExecution = [self.serviceEndpointLastExecution[serviceKey] doubleValue];
    CFAbsoluteTime deltaTime = CFAbsoluteTimeGetCurrent() - lastExecution;
    CFAbsoluteTime cutoffTime = 1.0 / requestsPerSecond;
    CFAbsoluteTime timeInterval = deltaTime - cutoffTime;
    if (timeInterval < 0.0) {
        timeInterval = 0.0;
    }
    
    return timeInterval;
}

- (void)executedRequest:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromRequest:request];
    self.serviceEndpointLastExecution[serviceKey] = @(CFAbsoluteTimeGetCurrent());
}

- (double)requestsPerSecondForServiceKey:(NSString *)serviceKey
{
    return [self.serviceEndpointRequestsPerSecond[serviceKey] doubleValue] ?: self.requestsPerSecond;
}

- (NSString *)serviceKeyFromRequest:(SPTDataLoaderRequest *)request
{
    NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSURLComponents *serviceComponents = [NSURLComponents new];
    serviceComponents.scheme = requestComponents.scheme;
    serviceComponents.host = requestComponents.host;
    serviceComponents.path = requestComponents.path.pathComponents.firstObject;
    NSString *serviceKey = serviceComponents.URL.absoluteString;
    return serviceKey;
}

@end
