#import <Foundation/Foundation.h>

@class SPTDataLoader;

/**
 * A factory for producing data loaders and automatically authorising requests
 */
@interface SPTDataLoaderFactory : NSObject

/**
 * Whether the factory is simulating being offline
 * @discussion This forces all requests to only use local caching and never reach a remote server
 */
@property (nonatomic, assign, getter = isOffline) BOOL offline;
/**
 * The objects authorising HTTP requests for this factory
 * @discussion The NSArray consists of objects conforming to the SPTDataLoaderAuthoriser protocol
 */
@property (nonatomic, copy, readonly) NSArray *authorisers;

/**
 * Creates a data loader
 */
- (SPTDataLoader *)createDataLoader;

@end
