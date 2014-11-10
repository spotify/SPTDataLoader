#import "SPTCancellationTokenFactoryImplementation.h"

#import "SPTCancellationTokenImplementation.h"

@implementation SPTCancellationTokenFactoryImplementation

#pragma mark SPTCancellationTokenFactory

- (id<SPTCancellationToken>)createCancellationTokenWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
{
    return [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:delegate];
}

@end
