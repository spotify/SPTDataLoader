/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderDelegate.h>

@interface SPTDataLoaderDelegateMock : NSObject <SPTDataLoaderDelegate>

@property (nonatomic, assign) BOOL supportChunks;
@property (nonatomic, assign) BOOL respondsToBodyStreamPrompts;
@property (nonatomic, assign) NSUInteger numberOfCallsToSuccessfulResponse;
@property (nonatomic, assign) NSUInteger numberOfCallsToErrorResponse;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancelledRequest;
@property (nonatomic, assign) NSUInteger numberOfCallsToReceiveDataChunk;
@property (nonatomic, assign) NSUInteger numberOfCallsToReceivedInitialResponse;
@property (nonatomic, assign) NSUInteger numberOfCallsToNeedNewBodyStream;
@property (nonatomic, strong) dispatch_block_t receivedSuccessfulBlock;

@end
