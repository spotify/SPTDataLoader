#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;

@protocol SPTCancellationToken;
@protocol SPTDataLoaderRequestResponseHandler;

/**
 * A private delegate API for the creator of SPTDataLoader to use for routing requests through a user authentication
 * layer
 */
@protocol SPTDataLoaderRequestResponseHandlerDelegate <NSObject>

/**
 * Performs a request
 * @param requestResponseHandler The object that can perform requests and responses
 * @param request The object describing the request to perform
 */
- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request;

@end

@protocol SPTDataLoaderRequestResponseHandler <NSObject>

/**
 * The object to delegate performing requests to
 */
@property (nonatomic, weak, readonly) id<SPTDataLoaderRequestResponseHandlerDelegate> requestResponseHandlerDelegate;

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
