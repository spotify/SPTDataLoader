#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

/**
 * A rate limiter for configuring custom rates on a per service basis
 */
@interface SPTDataLoaderRateLimiter : NSObject

/**
 * Class constructor
 * @param requestsPerSecond The number of requests per second as a default to allow for a service
 */
+ (instancetype)rateLimiterWithDefaultRequestsPerSecond:(double)requestsPerSecond;

/**
 * Finds the earliest time until a request can be executed
 * @param request The request pending for execution
 */
- (NSTimeInterval)earliestTimeUntilRequestCanBeExecuted:(SPTDataLoaderRequest *)request;
/**
 * Tells the rate limiter a request is currently being executed
 * @param request The request being executed
 */
- (void)executedRequest:(SPTDataLoaderRequest *)request;

@end
