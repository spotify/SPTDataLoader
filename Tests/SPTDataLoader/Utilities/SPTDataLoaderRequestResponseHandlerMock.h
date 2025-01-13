/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@class SPTDataLoaderResponse;

@interface SPTDataLoaderRequestResponseHandlerMock : NSObject <SPTDataLoaderRequestResponseHandler>

@property (nonatomic, assign, readonly) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfSuccessfulDataResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedInitialResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfNewBodyStreamCalls;
@property (nonatomic, strong, readonly) SPTDataLoaderResponse *lastReceivedResponse;
@property (nonatomic, assign, readwrite, getter = isAuthorising) BOOL authorising;
@property (nonatomic, strong, readwrite) dispatch_block_t failedResponseBlock;

@end
