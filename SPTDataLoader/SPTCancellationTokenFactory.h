#import <Foundation/Foundation.h>

@protocol SPTCancellationToken;
@protocol SPTCancellationTokenDelegate;

/**
 * A factory for creating generic cancellation tokens
 */
@protocol SPTCancellationTokenFactory <NSObject>

/**
 * Create a cancellation token
 * @param delegate The object listening to the cancellation token
 */
- (id<SPTCancellationToken>)createCancellationTokenWithDelegate:(id<SPTCancellationTokenDelegate>)delegate;

@end
