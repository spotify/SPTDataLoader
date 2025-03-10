/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderTimeProviderMock: NSObject <SPTDataLoaderTimeProvider>

@property (nonatomic, readwrite) CFAbsoluteTime currentTime;

@end

NS_ASSUME_NONNULL_END
