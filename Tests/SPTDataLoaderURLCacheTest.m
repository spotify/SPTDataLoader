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
#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderResponse.h>

#import "SPTDataLoaderURLCache.h"

@interface SPTDataLoaderURLCacheTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderURLCache *cache;

@end

@implementation SPTDataLoaderURLCacheTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.cache = [SPTDataLoaderURLCache new];
}

#pragma mark SPTDataLoaderResolverTest

- (void)testNotNil
{
    XCTAssertNotNil(self.cache, @"The cache should not be nil after construction");
}

- (void)testStoreCachedResponseForRequest
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    NSHTTPURLResponse *dummyResponse = [[NSHTTPURLResponse alloc] initWithURL:URL
                                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                                  HTTPVersion:@"2.0"
                                                                 headerFields:[NSDictionary<NSString *,NSString *> new]];
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:dummyResponse
                                                                                   data:[NSData new]];
    [self.cache storeCachedResponse:cachedResponse forRequest:request];
    cachedResponse = [self.cache cachedResponseForRequest:request];
    NSURLResponse *response = cachedResponse.response;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        dummyResponse = (NSHTTPURLResponse *)response;
        NSDictionary *headers = dummyResponse.allHeaderFields;
        NSString *value = [headers valueForKey:SPTDataLoaderURLCacheSpecialHeader];
        XCTAssertNotNil(value, @"The value for Cache Special Header should not be nil");
        XCTAssertEqualObjects(value, @"YES", @"The value for Cache Special Header should be YES");
    }
}

@end
