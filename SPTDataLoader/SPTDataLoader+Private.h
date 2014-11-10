#import "SPTDataLoader.h"

/**
 * A private delegate API for the creator of SPTDataLoader to use for routing requests through a user authentication
 * layer
 */
@protocol SPTDataLoaderPrivateDelegate <NSObject>

/**
 * Performs a request
 * @param request The object describing the request to perform
 */
- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request;

@end

/**
 * The private API for the data loader for internal use in the SPTDataLoader library
 */
@interface SPTDataLoader (Private)

/**
 * The object to delegate performing requests to
 */
@property (nonatomic, weak) id<SPTDataLoaderPrivateDelegate> privateDelegate;

/**
 * Call when a response successfully completed
 * @param response The response that successfully completed
 */
- (void)successfulResponse:(SPTDataLoaderResponse *)response;
/**
 * Call when a response failed to complete
 * @param response The response that failed to complete
 */
- (void)failedResponse:(SPTDataLoaderResponse *)response;
/**
 * Call when a request becomes cancelled
 * @param request The request that was cancelled
 */
- (void)cancelledRequest:(SPTDataLoaderRequest *)request;

@end
