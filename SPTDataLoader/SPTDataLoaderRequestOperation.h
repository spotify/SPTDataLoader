#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;
@class SPTDataLoaderRequestOperation;

@protocol SPTCancellationToken;
@protocol SPTDataLoaderRequestResponseHandler;

/**
 * The tasks the operation delegates to its creator
 */
@protocol SPTDataLoaderRequestOperationDelegate <NSObject>

/**
 * Called when the operation needs to know how much time is left before the execution of a URL can begin
 * @param requestOperation The operation making the request
 * @param URL The URL the operation is making a request on
 */
- (NSTimeInterval)dataLoaderRequestOperation:(SPTDataLoaderRequestOperation *)requestOperation
                timeLeftUntilExecutionForURL:(NSURL *)URL;

@end

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
 * The object listening to a request operation
 */
@property (nonatomic, weak) id<SPTDataLoaderRequestOperationDelegate> delegate;
/**
 * The request response handler to callback to
 */
@property (nonatomic, weak, readonly) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;

/**
 * Class constructor
 * @param request The request object to perform lookup with
 * @param task The task to perform
 * @param cancellationToken The token to use to cancel the request with
 * @param requestResponseHandler The object tie to this operation for potential callbacks
 */
+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken
                               requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler;

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
