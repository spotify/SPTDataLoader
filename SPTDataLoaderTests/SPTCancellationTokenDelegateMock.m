#import "SPTCancellationTokenDelegateMock.h"

@implementation SPTCancellationTokenDelegateMock

- (void)cancellationTokenDidCancel:(id<SPTCancellationToken>)cancellationToken
{
    self.numberOfCallsToCancellationTokenDidCancel++;
}

@end
