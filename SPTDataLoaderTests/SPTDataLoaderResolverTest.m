/*
 * Copyright (c) 2015-2016 Spotify AB.
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
@import XCTest;

#import "SPTDataLoaderResolver.h"

@interface SPTDataLoaderResolverTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResolver *resolver;

@end

@implementation SPTDataLoaderResolverTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.resolver = [SPTDataLoaderResolver new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderResolverTest

- (void)testNotNil
{
    XCTAssertNotNil(self.resolver, @"The resolver should not be nil after construction");
}

- (void)testDefaultToHostIfNoOverridingAddress
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    NSString *address = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(URL.host, address, @"The address should be identical to the URL host if no overrides are supplied");
}

- (void)testAddressGivenIfReachableForHostOverride
{
    NSString *overrideAddresss = @"192.168.0.1";
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    [self.resolver setAddresses:@[ overrideAddresss ] forHost:(NSString * _Nonnull)URL.host];
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(host, overrideAddresss, @"The address should be overridden");
}

- (void)testAddressNotGivenIfNotReachableForHostOverride
{
    NSString *overrideAddresss = @"192.168.0.1";
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    [self.resolver setAddresses:@[ overrideAddresss ] forHost:(NSString * _Nonnull)URL.host];
    [self.resolver markAddressAsUnreachable:overrideAddresss];
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(host, URL.host, @"The address should not be overridden if unreachable");
}

@end
