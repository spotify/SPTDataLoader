/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SPTDataLoaderTimeProvider <NSObject>

@property (nonatomic, readonly) CFAbsoluteTime currentTime;

@end

NS_ASSUME_NONNULL_END
