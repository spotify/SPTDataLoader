/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSURLSessionTaskMock.h"

@implementation NSURLSessionTaskMock

@synthesize countOfBytesSent;
@synthesize countOfBytesReceived;
@synthesize countOfBytesExpectedToSend = _countOfBytesExpectedToSend;
@synthesize countOfBytesExpectedToReceive = _countOfBytesExpectedToReceive;
@synthesize currentRequest;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _countOfBytesExpectedToSend = NSURLSessionTransferSizeUnknown;
        _countOfBytesExpectedToReceive = NSURLSessionTransferSizeUnknown;
    }
    return self;
}

#pragma mark NSURLSessionTaskMock

- (void)resume
{
    self.numberOfCallsToResume++;
    if (self.resumeCallback) {
        self.resumeCallback();
    }
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

- (NSURLResponse *)response
{
    return self.mockResponse;
}

@end
