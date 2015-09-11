#import <Foundation/Foundation.h>

#import "SPTCancellationToken.h"

@interface SPTCancellationTokenDelegateMock : NSObject <SPTCancellationTokenDelegate>

@property (nonatomic, assign) NSUInteger numberOfCallsToCancellationTokenDidCancel;

@end
