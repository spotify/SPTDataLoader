#import "SPTDataLoaderFactory.h"

#import "SPTDataLoader+Private.h"

/**
 * The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private)

/**
 * The object to delegate performing the requests to
 */
@property (nonatomic, weak, readonly) id<SPTDataLoaderPrivateDelegate> privateDelegate;

/**
 * Class constructor
 * @param privateDelegate The private delegate to delegate request handling to
 */
+ (instancetype)dataLoaderFactoryWithPrivateDelegate:(id<SPTDataLoaderPrivateDelegate>)privateDelegate;

@end
