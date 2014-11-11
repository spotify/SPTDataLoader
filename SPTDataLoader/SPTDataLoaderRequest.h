#import <Foundation/Foundation.h>

/**
 * A representing of the request to make to the backend
 */
@interface SPTDataLoaderRequest : NSObject <NSCopying>

/**
 * The URL to request
 */
@property (nonatomic, strong) NSURL *URL;
/**
 * The number of times to retry this request
 */
@property (nonatomic, assign) NSUInteger retryCount;
/**
 * The body of the request
 */
@property (nonatomic, strong) NSData *body;

@end
