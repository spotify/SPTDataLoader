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

NS_ASSUME_NONNULL_BEGIN

@class SPTDataLoaderRequest;


/**
 A @c SPTDataLoaderServiceSessionSelector is responsible for selecting the most appropriate @c NSURLSession for a
 given request.
 */
@protocol SPTDataLoaderServiceSessionSelector <NSObject>

- (NSURLSession *)URLSessionForRequest:(SPTDataLoaderRequest *)request;
- (void)invalidateAndCancel;
@end

/**
 Production implementation of @c SPTDataLoaderServiceSessionSelector .
 */
@interface SPTDataLoaderServiceDefaultSessionSelector: NSObject <SPTDataLoaderServiceSessionSelector>

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                             delegate:(id<NSURLSessionDelegate>)delegate
                        delegateQueue:(NSOperationQueue *)delegateQueue;

@end

NS_ASSUME_NONNULL_END
