/*
 Copyright 2015-2022 Spotify AB

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
