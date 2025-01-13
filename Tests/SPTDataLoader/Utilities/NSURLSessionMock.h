/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@class NSURLSessionDataTaskMock;
@class NSURLSessionDownloadTaskMock;

@interface NSURLSessionMock : NSURLSession

@property (nonatomic, strong) NSURLSessionDataTaskMock *lastDataTask;
@property (nonatomic, strong) NSURLSessionDownloadTaskMock *lastDownloadTask;

@end
