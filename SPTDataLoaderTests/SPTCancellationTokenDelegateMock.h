@import Foundation;

#import "SPTCancellationToken.h"

@interface SPTCancellationTokenDelegateMock : NSObject <SPTCancellationTokenDelegate>

@property (nonatomic, assign) NSUInteger numberOfCallsToCancellationTokenDidCancel;

@end
