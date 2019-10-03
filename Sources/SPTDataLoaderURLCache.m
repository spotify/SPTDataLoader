/*
 Copyright (c) 2015-2019 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import "SPTDataLoaderURLCache.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const SPTDataLoaderURLCacheSpecialHeader = @"X-SPTDataLoader-Cache-Header";

@interface SPTDataLoaderURLCache ()

@end

@implementation SPTDataLoaderURLCache

#pragma mark SPTDataLoaderURLCache

- (NSCachedURLResponse *)addCachedHeaderToResponse:(NSCachedURLResponse *)cachedResponse
{
    if ([cachedResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse*) cachedResponse.response;
        NSMutableDictionary *headers = [response.allHeaderFields mutableCopy];
        headers[SPTDataLoaderURLCacheSpecialHeader] = @"YES";
        NSURL *url = response.URL;
        response = [[NSHTTPURLResponse new] initWithURL:url statusCode:response.statusCode HTTPVersion:@"HTTP/2.0" headerFields:headers];
        cachedResponse = [[NSCachedURLResponse new] initWithResponse:(NSURLResponse *) response data:cachedResponse.data];
    }
    return cachedResponse;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
    cachedResponse = [self addCachedHeaderToResponse:cachedResponse];
    [super storeCachedResponse:cachedResponse forRequest:request];
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forDataTask:(NSURLSessionDataTask *)dataTask
{
    cachedResponse = [self addCachedHeaderToResponse:cachedResponse];
    [super storeCachedResponse:cachedResponse forDataTask:dataTask];
}

@end

NS_ASSUME_NONNULL_END
