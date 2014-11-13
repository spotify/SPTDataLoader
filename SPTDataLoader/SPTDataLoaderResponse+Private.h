#import <SPTDataLoader/SPTDataLoaderResponse.h>

@class SPTDataLoaderRequest;

/**
 * A private delegate API for the objects in the SPTDataLoader library to use
 */
@interface SPTDataLoaderResponse (Private)

/**
 * The error that the request generated
 */
@property (nonatomic, strong, readwrite) NSError *error;
/**
 * Allows private consumers to alter the data for the response
 */
@property (nonatomic, strong, readwrite) NSData *body;

/**
 * Class constructor
 * @param request The request object making up the response
 * @param response The URL response received from the session
 */
+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request response:(NSURLResponse *)response;

/**
 * Whether we should retry the current request based on the current response data
 */
- (BOOL)shouldRetry;

@end
