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

#import "SPTDataLoaderInterceptorChain.h"

#import <SPTDataLoader/SPTDataLoaderInterceptor.h>
#import <SPTDataLoader/SPTDataLoaderInterceptorResult.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>

@interface SPTDataLoaderInterceptorChain()

@property (nonatomic, readonly) NSArray<id<SPTDataLoaderInterceptor>> *interceptors;

@end

@implementation SPTDataLoaderInterceptorChain

- (instancetype)initWithInterceptors:(NSArray<id<SPTDataLoaderInterceptor>> *)interceptors
{
    self = [super init];
    if (self) {
        _interceptors = interceptors;
    }
    return self;
}

- (SPTDataLoaderInterceptorResult *)decorateRequest:(SPTDataLoaderRequest *)request
{
    SPTDataLoaderRequest *decoratedRequest = request;
    for (id<SPTDataLoaderInterceptor> interceptor in _interceptors) {
        SPTDataLoaderInterceptorResult *result = [interceptor decorateRequest:decoratedRequest];
        if (result.type == SPTDataLoaderInterceptResultFailure) {
            return result;
        }
        decoratedRequest = result.value;
    }
    return [SPTDataLoaderInterceptorResult success:decoratedRequest];
}

- (SPTDataLoaderInterceptorResult *)decorateResponse:(SPTDataLoaderResponse *)response
{
    SPTDataLoaderResponse *decoratedResponse = response;
    for (id<SPTDataLoaderInterceptor> interceptor in _interceptors) {
        SPTDataLoaderInterceptorResult *result = [interceptor decorateResponse:decoratedResponse];
        if (result.type == SPTDataLoaderInterceptResultFailure) {
            return result;
        }
        decoratedResponse = result.value;
    }
    return [SPTDataLoaderInterceptorResult success:decoratedResponse];
}

@end
