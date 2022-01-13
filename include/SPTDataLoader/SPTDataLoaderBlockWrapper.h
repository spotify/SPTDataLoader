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

@class SPTDataLoader;
@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;
@protocol SPTDataLoaderCancellationToken;

typedef void (^SPTDataLoaderBlockCompletion)(SPTDataLoaderResponse * _Nonnull response, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

/**
 A wrapper providing a block interface for the common use case of SPTDataLoader
 */
@interface SPTDataLoaderBlockWrapper : NSObject

/// Initialises a data loader block wrapper
/// @param dataLoader An SPTDataLoader object
- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader;


/// Performs a request and returns a cancellation token associated with it.
/// @param request The object describing the kind of request to be performed
/// @param completion A completion block with the response and an error object
/// @return A cancellation token associated with the request, or `nil` if the request coulnd’t be performed.
- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
                                                   completion:(SPTDataLoaderBlockCompletion)completion;

@end

NS_ASSUME_NONNULL_END
