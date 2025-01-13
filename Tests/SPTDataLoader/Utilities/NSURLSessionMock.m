/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSURLSessionMock.h"
#import "NSURLSessionDataTaskMock.h"
#import "NSURLSessionDownloadTaskMock.h"

@implementation NSURLSessionMock

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
{
    self.lastDataTask = [NSURLSessionDataTaskMock new];
    return self.lastDataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
{
    self.lastDownloadTask = [NSURLSessionDownloadTaskMock new];
    return self.lastDownloadTask;
}

@end
