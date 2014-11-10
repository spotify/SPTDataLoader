#import <Foundation/Foundation.h>

/**
 * A representing of the request to make to the backend
 */
@interface SPTDataLoaderRequest : NSObject

/**
 * The URL to request
 */
@property (nonatomic, strong) NSURL *URL;

@end
