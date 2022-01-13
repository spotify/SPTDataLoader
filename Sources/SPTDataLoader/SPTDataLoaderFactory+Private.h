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

#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderRequestResponseHandlerDelegate;
@protocol SPTDataLoaderAuthoriser;

NS_ASSUME_NONNULL_BEGIN

/**
 The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private) <SPTDataLoaderRequestResponseHandler>

/**
 Class constructor
 @param requestResponseHandlerDelegate The private delegate to delegate request handling to
 @param authorisers An NSArray of SPTDataLoaderAuthoriser objects for supporting different forms of authorisation
 */
+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(nullable id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(nullable NSArray<id<SPTDataLoaderAuthoriser>> *)authorisers;

@end

NS_ASSUME_NONNULL_END
