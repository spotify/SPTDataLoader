#import "SPTDataLoaderRequest.h"

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderRequest (Private)

/**
 * The URL request representing this request
 */
@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;

/**
 * Whether we should retry a failed response
 * @param response The response received from the server
 * @param error The object describing the failure
 */
- (BOOL)shouldRetryForResponse:(NSURLResponse *)response error:(NSError *)error;

@end
