#import "SPTDataLoaderConsumptionObserverMock.h"

@implementation SPTDataLoaderConsumptionObserverMock

- (void)endedRequest:(SPTDataLoaderRequest *)request
     bytesDownloaded:(int)bytesDownloaded
       bytesUploaded:(int)bytesUploaded
{
    self.numberOfCallsToEndedRequest++;
}

@end
