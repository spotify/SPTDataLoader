/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSURLSessionDownloadTaskMock.h"

@implementation NSURLSessionDownloadTaskMock

@synthesize countOfBytesSent;
@synthesize countOfBytesReceived;
@synthesize currentRequest;
@synthesize response;

- (void)resume
{
    self.numberOfCallsToResume++;
}

- (void)cancel
{
    self.numberOfCallsToCancel++;
}

@end
