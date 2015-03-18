/*
 * Copyright (c) 2015 Spotify AB.
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
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequest+Private.h"

NSString * const SPTDataLoaderRequestHostHeader = @"Host";

static NSString * const NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod);

@interface SPTDataLoaderRequest ()

@property (nonatomic, assign, readwrite) int64_t uniqueIdentifier;

@property (nonatomic, strong) NSMutableDictionary *mutableHeaders;
@property (nonatomic, assign) BOOL retriedAuthorisation;

@property (nonatomic, weak) id<SPTCancellationToken> cancellationToken;

@end

@implementation SPTDataLoaderRequest

#pragma mark SPTDataLoaderRequest

+ (instancetype)requestWithURL:(NSURL *)URL
{
    return [[self alloc] initWithURL:URL];
}

- (instancetype)initWithURL:(NSURL *)URL
{
    static int64_t uniqueIdentifierBarrier = 0;
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _URL = URL;
    
    _mutableHeaders = [NSMutableDictionary new];
    _method = SPTDataLoaderRequestMethodGet;
    @synchronized(self.class) {
        _uniqueIdentifier = uniqueIdentifierBarrier++;
    }
    
    return self;
}

- (NSDictionary *)headers
{
    @synchronized(self.mutableHeaders) {
        return [self.mutableHeaders copy];
    }
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    if (!header) {
        return;
    }
    
    @synchronized(self.mutableHeaders) {
        if (!value && header) {
            [self.mutableHeaders removeObjectForKey:header];
            return;
        }
        
        self.mutableHeaders[header] = value;
    }
}

- (void)removeHeader:(NSString *)header
{
    @synchronized(self.mutableHeaders) {
        [self.mutableHeaders removeObjectForKey:header];
    }
}

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    NSString * const SPTDataLoaderRequestContentLengthHeader = @"Content-Length";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.URL];
    
    if (!self.headers[SPTDataLoaderRequestHostHeader]) {
        [urlRequest addValue:self.URL.host forHTTPHeaderField:SPTDataLoaderRequestHostHeader];
    }
    
    if (self.body) {
        [urlRequest addValue:@(self.body.length).stringValue forHTTPHeaderField:SPTDataLoaderRequestContentLengthHeader];
        urlRequest.HTTPBody = self.body;
    }
    
    NSDictionary *headers = self.headers;
    for (NSString *key in headers) {
        NSString *value = headers[key];
        [urlRequest addValue:value forHTTPHeaderField:key];
    }
    
    urlRequest.cachePolicy = self.cachePolicy;
    urlRequest.HTTPMethod = NSStringFromSPTDataLoaderRequestMethod(self.method);
    
    return urlRequest;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class requestWithURL:self.URL];
    copy.maximumRetryCount = self.maximumRetryCount;
    copy.body = [self.body copy];
    @synchronized(self.mutableHeaders) {
        copy.mutableHeaders = [self.mutableHeaders mutableCopy];
    }
    copy.chunks = self.chunks;
    copy.cachePolicy = self.cachePolicy;
    copy.skipNSURLCache = self.skipNSURLCache;
    copy.method = self.method;
    copy.userInfo = self.userInfo;
    copy.uniqueIdentifier = self.uniqueIdentifier;
    return copy;
}

@end

static NSString * const SPTDataLoaderRequestDeleteMethodString = @"DELETE";
static NSString * const SPTDataLoaderRequestGetMethodString = @"GET";
static NSString * const SPTDataLoaderRequestPostMethodString = @"POST";
static NSString * const SPTDataLoaderRequestPutMethodString = @"PUT";

static NSString * const NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod)
{
    switch (requestMethod) {
        case SPTDataLoaderRequestMethodDelete: return SPTDataLoaderRequestDeleteMethodString;
        case SPTDataLoaderRequestMethodGet: return SPTDataLoaderRequestGetMethodString;
        case SPTDataLoaderRequestMethodPost: return SPTDataLoaderRequestPostMethodString;
        case SPTDataLoaderRequestMethodPut: return SPTDataLoaderRequestPutMethodString;
    }
}
