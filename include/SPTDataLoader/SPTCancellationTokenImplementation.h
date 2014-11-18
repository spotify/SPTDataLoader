#import <Foundation/Foundation.h>

#import "SPTCancellationToken.h"

/**
 * The implementation for the cancellation token API
 */
@interface SPTCancellationTokenImplementation : NSObject <SPTCancellationToken>

/**
 * Class constructor
 * @param delegate The object listening to the cancellation token
 * @param cancelObject The object that will be cancelled
 */
+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
                                               cancelObject:(id)cancelObject;

@end
