/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSURLSessionDataTaskMock.h"

@implementation NSURLSessionDataTaskMock

@synthesize countOfBytesSent;
@synthesize countOfBytesReceived;
@synthesize countOfBytesExpectedToSend = _countOfBytesExpectedToSend;
@synthesize countOfBytesExpectedToReceive = _countOfBytesExpectedToReceive;
@synthesize currentRequest;
@synthesize response;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _countOfBytesExpectedToSend = NSURLSessionTransferSizeUnknown;
        _countOfBytesExpectedToReceive = NSURLSessionTransferSizeUnknown;
    }
    return self;
}

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

@end
