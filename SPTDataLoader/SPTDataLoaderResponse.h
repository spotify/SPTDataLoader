#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

extern NSString * const SPTDataLoaderResponseErrorDomain;

/**
 * An object representing the response from the backend
 */
@interface SPTDataLoaderResponse : NSObject

/**
 * The request object that generated the request
 */
@property (nonatomic, strong, readonly) SPTDataLoaderRequest *request;
/**
 * The error that the request generated
 */
@property (nonatomic, strong, readonly) NSError *error;

@end
