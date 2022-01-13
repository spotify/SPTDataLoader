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

#import "SPTDataLoaderRequestResponseHandler.h"

@class SPTDataLoaderResponse;

@interface SPTDataLoaderRequestResponseHandlerMock : NSObject <SPTDataLoaderRequestResponseHandler>

@property (nonatomic, assign, readonly) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfSuccessfulDataResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedInitialResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfNewBodyStreamCalls;
@property (nonatomic, strong, readonly) SPTDataLoaderResponse *lastReceivedResponse;
@property (nonatomic, assign, readwrite, getter = isAuthorising) BOOL authorising;
@property (nonatomic, strong, readwrite) dispatch_block_t failedResponseBlock;

@end
