/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderResolverAddress.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderResolverAddress ()

@property (nonatomic, assign, readonly) NSTimeInterval stalePeriod;
@property (nonatomic, assign) CFAbsoluteTime lastFailedTime;

@end

@implementation SPTDataLoaderResolverAddress

#pragma mark SPTDataLoaderResolverAddress

- (BOOL)isReachable
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval deltaTime = currentTime - self.lastFailedTime;
    if (deltaTime < 0.0) {
        return YES;
    }

    return deltaTime > self.stalePeriod;
}

+ (instancetype)dataLoaderResolverAddressWithAddress:(NSString *)address
{
    return [[self alloc] initWithAddress:address];
}

- (instancetype)initWithAddress:(NSString *)address
{
    const NSTimeInterval SPTDataLoaderResolverAddressDefaultStalePeriodOneHour = 60.0 * 60.0;

    self = [super init];
    if (self) {
        _address = address;
        _stalePeriod = SPTDataLoaderResolverAddressDefaultStalePeriodOneHour;
    }

    return self;
}

- (void)failedToReach
{
    self.lastFailedTime = CFAbsoluteTimeGetCurrent();
}

@end

NS_ASSUME_NONNULL_END
