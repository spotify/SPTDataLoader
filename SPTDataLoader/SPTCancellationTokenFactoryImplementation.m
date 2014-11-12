#import <SPTDataLoader/SPTCancellationTokenFactoryImplementation.h>

#import <SPTDataLoader/SPTCancellationTokenImplementation.h>

@implementation SPTCancellationTokenFactoryImplementation

#pragma mark SPTCancellationTokenFactory

- (id<SPTCancellationToken>)createCancellationTokenWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
{
    return [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:delegate];
}

@end
