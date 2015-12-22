#import "SPTDataLoaderConsumptionObserverMock.h"

@implementation SPTDataLoaderConsumptionObserverMock

- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response
                 bytesDownloaded:(int)bytesDownloaded
                   bytesUploaded:(int)bytesUploaded
{
    self.numberOfCallsToEndedRequest++;
}

@end
