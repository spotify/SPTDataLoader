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

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SPTDataLoaderInterceptResultType) {
    SPTDataLoaderInterceptResultSuccess,
    SPTDataLoaderInterceptResultFailure,
};

@interface SPTDataLoaderInterceptorResult : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*! Constructs a result that holds a value. */
+ (SPTDataLoaderInterceptorResult *)success:(id)value;
/*! Constructs a result that holds an error. */
+ (SPTDataLoaderInterceptorResult *)failure:(NSError *)error;

/*! It inform which on of value or error property can be accessed. */
@property (nonatomic, readonly) SPTDataLoaderInterceptResultType type;
/*! A value contained in a success result. Asserts if it is a failure result. */
@property (nonatomic, readonly, nonnull) id value;
/*! An error contained in a failure result. Asserts if it is a success result. */
@property (nonatomic, readonly, nonnull) NSError *error;

@end

NS_ASSUME_NONNULL_END
