#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

@protocol SPTDataLoaderAuthoriser;

/**
 * A delegate used for the object consuming the results of the authoriser
 */
@protocol SPTDataLoaderAuthoriserDelegate <NSObject>

/**
 * Called when the data loader authorises succeeds in authorising the request
 * @param dataLoaderAuthoriser The data loader authoriser that authorised the request
 * @param request The request the data loader authorised
 */
- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
         didAuthoriseRequest:(SPTDataLoaderRequest *)request;
/**
 * Called when the data loader authorised fails to authorise the request
 * @param dataLoaderAuthoriser The data loader authoriser that failed to authorise the request
 * @param request The request the data loader failed to authorise
 */
- (void)dataLoaderAuthoriser:(id<SPTDataLoaderAuthoriser>)dataLoaderAuthoriser
   didFailToAuthoriseRequest:(SPTDataLoaderRequest *)request;

@end

/**
 * An object that could act as an authoriser for injecting the required authorisation headers into a request
 */
@protocol SPTDataLoaderAuthoriser <NSObject>

/**
 * The object listening to the data loader authoriser
 */
@property (nonatomic, weak) id<SPTDataLoaderAuthoriserDelegate> delegate;
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
 * @discussion This will invoke one of the delegate methods to be invoked after a failed or successful authorisation
 */
- (void)authoriseRequest:(SPTDataLoaderRequest *)request;

@end
