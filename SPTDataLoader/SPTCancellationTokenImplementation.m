#import <SPTDataLoader/SPTCancellationTokenImplementation.h>

@interface SPTCancellationTokenImplementation ()

@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property (nonatomic, weak, readwrite) id<SPTCancellationTokenDelegate> delegate;

@end

@implementation SPTCancellationTokenImplementation

#pragma mark SPTCancellationTokenImplementation

+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTCancellationTokenDelegate>)delegate
                                               cancelObject:(id)cancelObject
{
    return [[self alloc] initWithDelegate:delegate cancelObject:cancelObject];
}

- (instancetype)initWithDelegate:(id<SPTCancellationTokenDelegate>)delegate cancelObject:(id)cancelObject
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _delegate = delegate;
    _objectToCancel = cancelObject;
    
    return self;
}

#pragma mark SPTCancellationToken

@synthesize cancelled = _cancelled;
@synthesize delegate = _delegate;
@synthesize objectToCancel = _objectToCancel;

- (void)cancel
{
    if (self.cancelled) {
        return;
    }
    
    [self.delegate cancellationTokenDidCancel:self];
    
    self.cancelled = YES;
}

@end
