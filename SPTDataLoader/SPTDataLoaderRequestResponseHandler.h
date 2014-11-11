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

@optional

/**
 * Delegate a successfully authorised request
 * @param requestResponseHandler The handler that successfully authorised the request
 * @param request The request that contains the authorisation headers
 * @param cancellationToken The token used to cancel the request
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
             authorisedRequest:(SPTDataLoaderRequest *)request
             cancellationToken:(id<SPTCancellationToken>)cancellationToken;
/**
 * Delegate a failed authorisation attempt for a request
 * @param requestResponseHandler The handler that failed to authorise the request
 * @param request The request whose authorisation failed
 * @param cancellationToken The token used to cancel the request
 * @param error The object describing the failure in the authorisation request
 */
- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
      failedToAuthoriseRequest:(SPTDataLoaderRequest *)request
             cancellationToken:(id<SPTCancellationToken>)cancellationToken
                         error:(NSError *)error;

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

@optional

/**
 * Whether the request needs authorisation according to this handler
 * @param request The request that may need authorisation
 */
- (BOOL)shouldAuthoriseRequest:(SPTDataLoaderRequest *)request;
/**
 * Authorise a request
 * @param request The request to be authorise
 * @param cancellationToken The token used to cancel this request
 */
- (void)authoriseRequest:(SPTDataLoaderRequest *)request cancellationToken:(id<SPTCancellationToken>)cancellationToken;

@end
