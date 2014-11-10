#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

/**
 * An object representing the response from the backend
 */
@interface SPTDataLoaderResponse : NSObject

/**
 * The request object that generated the request
 */
@property (nonatomic, strong, readonly) SPTDataLoaderRequest *request;

@end
