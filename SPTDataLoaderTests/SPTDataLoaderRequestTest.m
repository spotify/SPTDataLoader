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
#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

@interface SPTDataLoaderRequestTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@property (nonatomic, strong) NSURL *URL;

@end

@implementation SPTDataLoaderRequestTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    self.request = [SPTDataLoaderRequest requestWithURL:self.URL sourceIdentifier:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRequestTest

- (void)testNotNil
{
    XCTAssertNotNil(self.request, @"The request should not be nil after construction");
}

- (void)testHeadersEmptyInitially
{
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should be empty when initially setting up the request");
}

- (void)testAddValueToNilHeader
{
    [self.request addValue:@"Value" forHeader:nil];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should not reflect an added value with an empty header");
}

- (void)testAddNilValueToHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    [self.request addValue:nil forHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should remove a header when added with an empty value");
}

- (void)testAddValueToHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{ @"Header" : @"Value" }, @"The headers should reflect the added header");
}

- (void)testRemoveHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    [self.request removeHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should not contain anything after removal");
}

- (void)testURLRequestAddsHostHeader
{
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Host"], self.URL.host, @"The URL request should add a host header field");
}

- (void)testURLRequestContentLengthHeader
{
    NSData *data = [@"Test" dataUsingEncoding:NSUTF8StringEncoding];
    self.request.body = data;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqual(@([request.allHTTPHeaderFields[@"Content-Length"] integerValue]).unsignedIntegerValue, data.length, @"The content-length header was reported incorrectly");
}

- (void)testURLRequestCopyingHeaders
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    NSURLRequest *request = self.request.urlRequest;
    NSDictionary *expectedHeaders = @{ @"Header" : @"Value",
                                       @"Host" : self.URL.host,
                                       @"Accept-Language" : [NSBundle mainBundle].preferredLocalizations.firstObject };
    XCTAssertEqualObjects(request.allHTTPHeaderFields, expectedHeaders, @"The headers were not copied appropriately");
}

- (void)testURLRequestCachePolicy
{
    self.request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqual(self.request.cachePolicy, request.cachePolicy, @"The URL request does not share the same cache policy as the request");
}

- (void)testURLRequestMethod
{
    self.request.method = SPTDataLoaderRequestMethodGet;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqualObjects(request.HTTPMethod, @"GET", @"The URL request did not set its HTTP method properly");
}

- (void)testCopy
{
    self.request.maximumRetryCount = 10;
    self.request.body = [@"Test" dataUsingEncoding:NSUTF8StringEncoding];
    [self.request addValue:@"Value" forHeader:@"Header"];
    self.request.chunks = YES;
    self.request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    self.request.skipNSURLCache = YES;
    self.request.method = SPTDataLoaderRequestMethodPost;
    SPTDataLoaderRequest *request = [self.request copy];
    XCTAssertEqual(request.maximumRetryCount, self.request.maximumRetryCount, @"The retry count was not copied correctly");
    XCTAssertEqualObjects(request.body, self.request.body, @"The body was not copied correctly");
    XCTAssertEqualObjects(request.headers, self.request.headers, @"The headers were not copied correctly");
    XCTAssertEqual(request.chunks, self.request.chunks, @"The chunk was not copied correctly");
    XCTAssertEqual(request.cachePolicy, self.request.cachePolicy, @"The cache policy was not copied correctly");
    XCTAssertEqual(request.skipNSURLCache, self.request.skipNSURLCache, @"'skipNSURLCache' was not copied correctly");
    XCTAssertEqual(request.method, self.request.method, @"The method was not copied correctly");
}

@end
