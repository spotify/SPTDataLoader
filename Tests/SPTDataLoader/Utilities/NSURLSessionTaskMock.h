/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@interface NSURLSessionTaskMock : NSURLSessionTask

@property (nonatomic, assign) NSUInteger numberOfCallsToResume;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancel;
@property (nonatomic, strong, readwrite, nullable) dispatch_block_t resumeCallback;
@property (nonatomic, strong, readwrite, nullable) NSURLResponse *mockResponse;

#pragma mark NSURLSessionTask

@property (atomic, readonly) int64_t countOfBytesSent;
@property (atomic, readonly) int64_t countOfBytesReceived;
@property (atomic, readonly) int64_t countOfBytesExpectedToSend;
@property (atomic, readonly) int64_t countOfBytesExpectedToReceive;
@property (atomic, nullable, readonly, copy) NSURLRequest *currentRequest;

@end
