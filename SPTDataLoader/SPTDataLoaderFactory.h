#import <Foundation/Foundation.h>

@class SPTDataLoader;

/**
 * A factory for producing data loaders and automatically authorising requests
 */
@interface SPTDataLoaderFactory : NSObject

/**
 * Creates a data loader
 */
- (SPTDataLoader *)createDataLoader;

@end
