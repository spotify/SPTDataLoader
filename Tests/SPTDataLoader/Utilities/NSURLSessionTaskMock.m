/*
 Copyright 2015-2023 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
