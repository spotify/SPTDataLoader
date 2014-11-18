#import <SPTDataLoader/SPTDataLoaderRequest.h>

@protocol SPTCancellationToken;

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderRequest (Private)

/**
 * The URL request representing this request
 */
@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;
/**
 * Whether the request has been retried with authorisation already
 * @warning This is not copied when a copy is performed
 */
@property (nonatomic, assign) BOOL retriedAuthorisation;

@end
