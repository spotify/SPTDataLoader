/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderRequestTaskHandlerDelegateMock.h"

#import "NSURLSessionTaskMock.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPTDataLoaderRequestTaskHandlerDelegateMock

- (NSURLSessionTaskMock *)task
{
    if (_task == nil) {
        _task = [[NSURLSessionTaskMock alloc] init];
    }

    return _task;
}

- (void)requestTaskHandlerNeedsNewTask:(SPTDataLoaderRequestTaskHandler *)requestTaskHandler
{
    requestTaskHandler.task = self.task;
}

@end

NS_ASSUME_NONNULL_END
