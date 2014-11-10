#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

@protocol SPTCancellationToken;

/**
 * The operation for performing a URL session task
 */
@interface SPTDataLoaderRequestOperation : NSOperation

/**
 * The token for cancelling the operation
 */
@property (nonatomic, strong, readonly) id<SPTCancellationToken> cancellationToken;

/**
 * Class constructor
 * @param request The request object to perform lookup with
 * @param task The task to perform
 * @param cancellationToken The token to use to cancel the request with
 */
+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken;

@end
