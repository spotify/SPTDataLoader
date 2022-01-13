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
