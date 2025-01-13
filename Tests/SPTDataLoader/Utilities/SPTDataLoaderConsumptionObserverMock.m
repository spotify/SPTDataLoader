/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderConsumptionObserverMock.h"

@implementation SPTDataLoaderConsumptionObserverMock

- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response
                 bytesDownloaded:(int)bytesDownloaded
                   bytesUploaded:(int)bytesUploaded
{
    self.numberOfCallsToEndedRequest++;
    self.lastBytesDownloaded = bytesDownloaded;
    if (self.endedRequestCallback) {
        self.endedRequestCallback();
    }
}

@end
