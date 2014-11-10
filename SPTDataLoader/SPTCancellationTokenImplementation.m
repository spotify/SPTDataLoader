#import "SPTCancellationTokenImplementation.h"

@interface SPTCancellationTokenImplementation ()

@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property (nonatomic, weak, readwrite) id<SPTCancellationTokenDelegate> delegate;

@end

@implementation SPTCancellationTokenImplementation

#pragma mark SPTCancellationTokenImplementation

+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _delegate = delegate;
    
    return self;
}

#pragma mark SPTCancellationToken

@synthesize cancelled = _cancelled;
@synthesize delegate = _delegate;

- (void)cancel
{
    if (self.cancelled) {
        return;
    }
    
    [self.delegate cancellationTokenDidCancel:self];
    
    self.cancelled = YES;
}

@end
