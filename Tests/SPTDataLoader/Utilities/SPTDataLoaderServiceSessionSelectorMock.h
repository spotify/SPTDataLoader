/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderServiceSessionSelector.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderServiceSessionSelectorMock : NSObject <SPTDataLoaderServiceSessionSelector>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithResolver:(NSURLSession *(^)(SPTDataLoaderRequest *))resolver NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
