#import "SPTDataLoaderFactory.h"

@protocol SPTDataLoaderRequestResponseHandlerDelegate;
@protocol SPTDataLoaderAuthoriser;

/**
 * The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private)

/**
 * Class constructor
 * @param requestResponseHandlerDelegate The private delegate to delegate request handling to
 * @param authorisers An NSArray of SPTDataLoaderAuthoriser objects for supporting different forms of authorisation
 */
+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(NSArray *)authorisers;

@end
