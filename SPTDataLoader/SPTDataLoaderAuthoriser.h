#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

@protocol SPTDataLoaderAuthoriser;

/**
 * An object that could act as an authoriser for injecting the required authorisation headers into a request
 */
@protocol SPTDataLoaderAuthoriser <NSObject, NSCopying>

/**
 * The identifier for the data loader authoriser
 * @discussion This should be unique for each type of authorisation
 */
@property (nonatomic, strong, readonly) NSString *identifier;

/**
 * Whether a request requires authorisation from this authoriser
 * @param request The request to check
 */
- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request;
/**
 * Authorise a request
 * @param request The request to authorise
 */
- (void)authoriseRequest:(SPTDataLoaderRequest *)request;

@end
