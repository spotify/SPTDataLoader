#import <Foundation/Foundation.h>

@protocol SPTCancellationToken;

/**
 * The protocol an object listening to the cancellation token must conform to
 */
@protocol SPTCancellationTokenDelegate <NSObject>

/**
 * Called when the cancellation token becomes cancelled
 * @param cancellationToken The cancellation token that became cancelled
 */
- (void)cancellationTokenDidCancel:(id<SPTCancellationToken>)cancellationToken;

@end

/**
 * A cancellation token used for cancelling specific requests
 */
@protocol SPTCancellationToken <NSObject>

/**
 * Whether the cancellation token has been cancelled
 */
@property (nonatomic, assign, readonly, getter = isCancelled) BOOL cancelled;
/**
 * The object listening to the cancellation token
 * @discussion This is immutable, the cancellation token should be fed this on its creation
 */
@property (nonatomic, weak, readonly) id<SPTCancellationTokenDelegate> delegate;

/**
 * Cancels the cancellation token
 */
- (void)cancel;

@end
