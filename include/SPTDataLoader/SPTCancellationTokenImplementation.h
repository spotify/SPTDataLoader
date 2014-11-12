#import <Foundation/Foundation.h>

#import "SPTCancellationToken.h"

/**
 * The implementation for the cancellation token API
 */
@interface SPTCancellationTokenImplementation : NSObject <SPTCancellationToken>

/**
 * Class constructor
 * @param delegate The object listening to the cancellation token
 */
+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTCancellationTokenDelegate>)delegate;

@end
