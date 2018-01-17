/*
 * Copyright (c) 2015-2018 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import "SPTDataLoaderRateLimiter.h"

#import "SPTDataLoaderRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderRateLimiter ()

@property (nonatomic, assign) double requestsPerSecond;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *serviceEndpointRequestsPerSecond;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *serviceEndpointLastExecution;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *serviceEndpointRetryAt;

@end

@implementation SPTDataLoaderRateLimiter

#pragma mark SPTDataLoaderRateLimiter

+ (instancetype)rateLimiterWithDefaultRequestsPerSecond:(double)requestsPerSecond
{
    return [[self alloc] initWithDefaultRequestsPerSecond:requestsPerSecond];
}

- (instancetype)initWithDefaultRequestsPerSecond:(double)requestsPerSecond
{
    self = [super init];
    if (self) {
        _requestsPerSecond = requestsPerSecond;
        _serviceEndpointRequestsPerSecond = [NSMutableDictionary new];
        _serviceEndpointLastExecution = [NSMutableDictionary new];
        _serviceEndpointRetryAt = [NSMutableDictionary new];
    }
    
    return self;
}

- (NSTimeInterval)earliestTimeUntilRequestCanBeExecuted:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromURL:request.URL];
    
    // First check if we are not accepting requests until a certain time (i.e. Retry-after header)
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime retryAtTime = 0.0;
    @synchronized(self.serviceEndpointRetryAt) {
        retryAtTime = [self.serviceEndpointRetryAt[serviceKey] doubleValue];
    }
    if (currentTime < retryAtTime) {
        return retryAtTime - currentTime;
    }
    
    // Next check that our rate limit is being respected
    double requestsPerSecond = [self requestsPerSecondForServiceKey:serviceKey];
    CFAbsoluteTime lastExecution = 0.0;
    @synchronized(self.serviceEndpointLastExecution) {
        lastExecution = [self.serviceEndpointLastExecution[serviceKey] doubleValue];
    }
    CFAbsoluteTime deltaTime = currentTime - lastExecution;
    CFAbsoluteTime cutoffTime = 1.0 / requestsPerSecond;
    CFAbsoluteTime timeInterval = cutoffTime - deltaTime;
    if (timeInterval < 0.0) {
        timeInterval = 0.0;
    }
    
    return timeInterval;
}

- (void)executedRequest:(SPTDataLoaderRequest *)request
{
    NSString *serviceKey = [self serviceKeyFromURL:request.URL];
    if (!serviceKey) {
        return;
    }
    
    @synchronized(self.serviceEndpointLastExecution) {
        self.serviceEndpointLastExecution[serviceKey] = @(CFAbsoluteTimeGetCurrent());
    }
    @synchronized(self.serviceEndpointRetryAt) {
        [self.serviceEndpointRetryAt removeObjectForKey:serviceKey];
    }
}

- (double)requestsPerSecondForURL:(NSURL *)URL
{
    return [self requestsPerSecondForServiceKey:[self serviceKeyFromURL:URL]];
}

- (void)setRequestsPerSecond:(double)requestsPerSecond forURL:(NSURL *)URL
{
    @synchronized(self.serviceEndpointRequestsPerSecond) {
        self.serviceEndpointRequestsPerSecond[[self serviceKeyFromURL:URL]] = @(requestsPerSecond);
    }
}

- (void)setRetryAfter:(NSTimeInterval)absoluteTime forURL:(NSURL *)URL
{
    if (!URL) {
        return;
    }
    
    @synchronized(self.serviceEndpointRetryAt) {
        self.serviceEndpointRetryAt[[self serviceKeyFromURL:URL]] = @(absoluteTime);
    }
}

- (double)requestsPerSecondForServiceKey:(NSString *)serviceKey
{
    @synchronized(self.serviceEndpointRequestsPerSecond) {
        NSNumber *value = self.serviceEndpointRequestsPerSecond[serviceKey];
        return (value != nil) ? value.doubleValue : self.requestsPerSecond;
    }
}

- (NSString *)serviceKeyFromURL:(NSURL *)URL
{
    if (!URL) {
        return @"";
    }

    NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    NSURLComponents *serviceComponents = [NSURLComponents new];
    serviceComponents.scheme = requestComponents.scheme;
    serviceComponents.host = requestComponents.host;
    serviceComponents.path = requestComponents.path.pathComponents.firstObject;
    NSString *serviceKey = serviceComponents.URL.absoluteString;
    return serviceKey;
}

@end

NS_ASSUME_NONNULL_END
