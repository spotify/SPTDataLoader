/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
