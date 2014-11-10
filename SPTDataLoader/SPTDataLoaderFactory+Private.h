#import "SPTDataLoaderFactory.h"

@protocol SPTDataLoaderRequestResponseHandlerDelegate;

/**
 * The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private)

/**
 * Class constructor
 * @param requestResponseHandlerDelegate The private delegate to delegate request handling to
 */
+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate;

@end
