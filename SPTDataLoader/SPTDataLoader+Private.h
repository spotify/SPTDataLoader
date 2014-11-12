#import <SPTDataLoader/SPTDataLoader.h>

#import "SPTDataLoaderRequestResponseHandler.h"

/**
 * The private API for the data loader for internal use in the SPTDataLoader library
 */
@interface SPTDataLoader (Private) <SPTDataLoaderRequestResponseHandler>

/**
 * Class constructor
 * @param requestResponseHandlerDelegate The private delegate for delegating the request handling
 */
+ (instancetype)dataLoaderWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate;

@end
