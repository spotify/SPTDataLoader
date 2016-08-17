#import "SPTDataLoaderCancellationTokenFactoryMock.h"

#import "SPTDataLoaderCancellationTokenImplementation.h"

@implementation SPTDataLoaderCancellationTokenFactoryMock

- (id<SPTDataLoaderCancellationToken>)createCancellationTokenWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                                             cancelObject:(id)cancelObject
{
    return [SPTDataLoaderCancellationTokenImplementation cancellationTokenImplementationWithDelegate:self.overridingDelegate ?: delegate
                                                                                        cancelObject:cancelObject];
}

@end
