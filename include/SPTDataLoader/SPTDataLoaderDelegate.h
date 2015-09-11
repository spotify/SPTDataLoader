#import <Foundation/Foundation.h>

@class SPTDataLoader;
@class SPTDataLoaderResponse;
@class SPTDataLoaderRequest;

/**
 * The protocol used for listening to the result of performing requests on the SPTDataLoader
 * @discussion One of the following callbacks are guaranteed to happen for every request being track by the data loader:
 * - didReceiveSuccessfulResponse
 * - didReceiveErrorResponse
 * - didCancelRequest
 */
@protocol SPTDataLoaderDelegate <NSObject>

/**
 * Called when the data loader received a successful response
 * @param dataLoader The data loader that received the successful response
 * @param response The object describing the response
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader received an error response
 * @param dataLoader The data loader that received the error response
 * @param response The object describing the response
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader cancels a request
 * @param dataLoader The data loader that cancelled the request
 * @param request The object describing the request that was cancelled
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request;

@optional

/**
 * Whether the data loader delegate will support chunks being called back
 * @param dataLoader The data loader asking the delegate for its support
 */
- (BOOL)dataLoaderShouldSupportChunks:(SPTDataLoader *)dataLoader;
/**
 * Called when the data loader receives a chunk of data for a request
 * @param dataLoader The data loader that receives the chunk
 * @param data The data that the data loader received
 * @param response The response that generated the data
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader
didReceiveDataChunk:(NSData *)data
       forResponse:(SPTDataLoaderResponse *)response;
/**
 * Called when the data loader receives an initial response for a request
 * @param dataLoader The data loader that received the initial response
 * @param response The response with all values filled out other than its body
 * @discussion This is guaranteed to be called before the first call of dataLoader:didReceiveDataChunk:forResponse
 */
- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveInitialResponse:(SPTDataLoaderResponse *)response;

@end
