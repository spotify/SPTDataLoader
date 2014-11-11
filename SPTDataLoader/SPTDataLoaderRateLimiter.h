#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

/**
 * A rate limiter for configuring custom rates on a per service basis
 * @discussion A service is defined as the scheme, host and first path component of the URL
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
/**
 * The amount of requests per second that are allowed to be executed on a URL
 * @param URL The URL to check the requests per second for
 */
- (double)requestsPerSecondForURL:(NSURL *)URL;
/**
 * Set the requests per second that are allowed to be executed on a URL
 * @param requestsPerSecond The number of requests per second to accept
 * @param URL The URL to check the requests per second for
 */
- (void)setRequestsPerSecond:(double)requestsPerSecond forURL:(NSURL *)URL;

@end
