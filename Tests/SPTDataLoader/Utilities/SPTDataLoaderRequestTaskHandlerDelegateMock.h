/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import "SPTDataLoaderRequestTaskHandler.h"

@class NSURLSessionTaskMock;

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderRequestTaskHandlerDelegateMock : NSObject <SPTDataLoaderRequestTaskHandlerDelegate>

@property (nonatomic) NSURLSessionTaskMock *task;

@end

NS_ASSUME_NONNULL_END
