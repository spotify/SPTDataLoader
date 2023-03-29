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

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderInterceptor.h>

@class SPTDataLoaderInterceptorResult;
@class SPTDataLoaderRequest;
@class SPTDataLoaderResponse;

@interface SPTDataLoaderInterceptorMock : NSObject<SPTDataLoaderInterceptor>

@property (nonatomic, assign, readonly) NSUInteger numberOfCallsToInterceptorRequest;
@property (nonatomic, assign, readonly) NSUInteger numberOfCallsToInterceptorResponse;
@property (nonatomic, copy, nullable) SPTDataLoaderInterceptorResult * _Nonnull(^interceptorRequestBlock)( SPTDataLoaderRequest * _Nonnull );
@property (nonatomic, copy, nullable) SPTDataLoaderInterceptorResult * _Nonnull(^interceptorResponseBlock)( SPTDataLoaderResponse * _Nonnull );

@end
