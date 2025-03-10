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

#import <SPTDataLoader/SPTDataLoaderInterceptorResult.h>

@implementation SPTDataLoaderInterceptorResult

@synthesize type=_type;
@synthesize value=_value;
@synthesize error=_error;

- (instancetype)initWithValue:(id)value {
    self = [super init];
    if (self) {
        _type = SPTDataLoaderInterceptResultSuccess;
        _value = value;
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error {
    self = [super init];
    if (self) {
        _type = SPTDataLoaderInterceptResultFailure;
        _error = error;
    }
    return self;
}

+ (SPTDataLoaderInterceptorResult *)success:(id)value {
    return [[SPTDataLoaderInterceptorResult alloc] initWithValue:value];
}

+ (SPTDataLoaderInterceptorResult *)failure:(NSError *)error {
    return [[SPTDataLoaderInterceptorResult alloc] initWithError:error];
}

- (id)value {
    NSAssert(_type == SPTDataLoaderInterceptResultSuccess, @"SPTDataLoaderInterceptorResult: not a success");
    return _value;
}

- (NSError *)error {
    NSAssert(_type == SPTDataLoaderInterceptResultFailure, @"SPTDataLoaderInterceptorResult: not a faliure");
    return _error;
}

@end
