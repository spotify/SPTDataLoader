#import "SPTDataLoaderRequest.h"

@protocol SPTCancellationToken;

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderRequest (Private)

/**
 * The URL request representing this request
 */
@property (nonatomic, strong, readonly) NSURLRequest *urlRequest;
@property (nonatomic, strong) id<SPTCancellationToken> cancellationToken;

@end
