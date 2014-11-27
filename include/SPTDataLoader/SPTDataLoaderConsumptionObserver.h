#import <Foundation/Foundation.h>

@class SPTDataLoaderRequest;

/**
 * The protocol an observer of the data loaders consumption must conform to
 */
@protocol SPTDataLoaderConsumptionObserver <NSObject>

/**
 * Called when a request ends (either via cancel or receiving a server response
 * @param bytesDownloaded The amount of bytes downloaded
 * @param bytesUploaded The amount of bytes uploaded
 */
- (void)endedRequest:(SPTDataLoaderRequest *)request
     bytesDownloaded:(int)bytesDownloaded
       bytesUploaded:(int)bytesUploaded;

@end
