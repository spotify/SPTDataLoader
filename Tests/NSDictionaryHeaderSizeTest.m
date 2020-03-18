/*
 Copyright (c) 2015-2020 Spotify AB.

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

#import "NSDictionary+HeaderSize.h"

@interface NSDictionaryHeaderSizeTest : XCTestCase

@end

@implementation NSDictionaryHeaderSizeTest

#pragma mark NSDictionaryHeaderSizeTest

- (void)testNoSizeForNonStringKeys
{
    NSDictionary *headers = @{ @(1) : @(2) };
    XCTAssertEqual(headers.byteSizeOfHeaders, 0, @"The header size in bytes should be 0 with no string keys");
}

- (void)testNoSizeForNonStringObjects
{
    NSDictionary *headers = @{ @"Authorisation" : @(1) };
    XCTAssertEqual(headers.byteSizeOfHeaders, 0, @"The header size in bytes should be 0 with no string objects");
}

- (void)testSize
{
    NSDictionary *headers = @{ @"Authorisation" : @"Basic thisismytoken" };
    XCTAssertEqual(headers.byteSizeOfHeaders, 35, @"The header size in bytes should be 35 inclusive of the \": \" barrier and \\n");
}

@end
