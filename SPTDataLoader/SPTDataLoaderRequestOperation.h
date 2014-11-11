#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;
@class SPTDataLoaderRateLimiter;

@protocol SPTCancellationToken;
@protocol SPTDataLoaderRequestResponseHandler;

/**
 * The operation for performing a URL session task
 */
@interface SPTDataLoaderRequestOperation : NSOperation

/**
 * The token for cancelling the operation
 */
@property (nonatomic, strong, readonly) id<SPTCancellationToken> cancellationToken;
/**
 * The task for performing the URL request on
 */
@property (nonatomic, strong, readonly) NSURLSessionTask *task;
/**
 * The request response handler to callback to
 */
@property (nonatomic, weak, readonly) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;
/**
 * The request being executed
 */
@property (nonatomic, strong, readonly) SPTDataLoaderRequest *request;

/**
 * Class constructor
 * @param request The request object to perform lookup with
 * @param task The task to perform
 * @param cancellationToken The token to use to cancel the request with
 * @param requestResponseHandler The object tie to this operation for potential callbacks
 * @param rateLimiter The object controlling the rate limits on a per service basis
 */
+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken
                               requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                          rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter;

/**
 * Call to tell the operation it has received some data
 * @param data The data from the URL session performing the task
 */
- (void)receiveData:(NSData *)data;
/**
 * Tell the operation the URL session has completed the request
 * @param error An optional error to use if the request was not completed successfully
 */
- (void)completeWithError:(NSError *)error;
/**
 * Call to tell the operation it has received a response
 * @param response The object describing the response it received from the server
 */
- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response;

@end
