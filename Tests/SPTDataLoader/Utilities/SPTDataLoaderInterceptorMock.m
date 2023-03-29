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

#import "SPTDataLoaderInterceptorMock.h"
#import <SPTDataLoader/SPTDataLoaderInterceptorResult.h>

@interface SPTDataLoaderInterceptorMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToInterceptorRequest;
@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToInterceptorResponse;

@end

@implementation SPTDataLoaderInterceptorMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _interceptorRequestBlock = nil;
        _interceptorResponseBlock = nil;
    }
    return self;
}

- (nonnull SPTDataLoaderInterceptorResult *)decorateRequest:(nonnull SPTDataLoaderRequest *)request {
    self.numberOfCallsToInterceptorRequest++;
    if (_interceptorRequestBlock) {
        return _interceptorRequestBlock(request);
    }
    return [SPTDataLoaderInterceptorResult success:request];
}

- (nonnull SPTDataLoaderInterceptorResult *)decorateResponse:(nonnull SPTDataLoaderResponse *)response { 
    self.numberOfCallsToInterceptorResponse++;
    if (_interceptorResponseBlock) {
        return _interceptorResponseBlock(response);
    }
    return [SPTDataLoaderInterceptorResult success:response];
}

@end
