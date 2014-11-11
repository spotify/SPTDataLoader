#import "SPTDataLoaderResponse.h"

@class SPTDataLoaderRequest;

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderResponse (Private)

/**
 * Class constructor
 * @param request The request object making up the response
 */
+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request;

@end
