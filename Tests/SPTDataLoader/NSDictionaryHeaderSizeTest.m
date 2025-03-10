/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
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
