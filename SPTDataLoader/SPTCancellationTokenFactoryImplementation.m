#import <SPTDataLoader/SPTCancellationTokenFactoryImplementation.h>

#import <SPTDataLoader/SPTCancellationTokenImplementation.h>

@implementation SPTCancellationTokenFactoryImplementation

#pragma mark SPTCancellationTokenFactory

- (id<SPTCancellationToken>)createCancellationTokenWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
                                                   cancelObject:(id)cancelObject
{
    return [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:delegate
                                                                              cancelObject:cancelObject];
}

@end
