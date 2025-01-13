/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderCancellationTokenImplementation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderCancellationTokenImplementation ()


@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;

@end

@implementation SPTDataLoaderCancellationTokenImplementation

#pragma mark SPTDataLoaderCancellationTokenImplementation

+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                               cancelObject:(nullable id)cancelObject
{
    return [[self alloc] initWithDelegate:delegate cancelObject:cancelObject];
}

- (instancetype)initWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate cancelObject:(nullable id)cancelObject
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _objectToCancel = cancelObject;
    }

    return self;
}

#pragma mark SPTDataLoaderCancellationToken

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

NS_ASSUME_NONNULL_END
