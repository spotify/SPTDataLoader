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

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class JSONResponseSerializerTest: XCTestCase {
    func test_responseSerialization_shouldBeUnsuccessful_whenErrorIsPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.error = TestError.foo

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertTrue(error is TestError)
    }

    func test_responseSerialization_shouldBeUnsuccessful_whenDataIsMissing() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error.domain, NSCocoaErrorDomain)
        XCTAssertEqual(error.code, 3840)
    }

    func test_responseSerialization_shouldBeUnsuccessful_whenDataIsInvalid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "{null}".data(using: .utf8)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error.domain, NSCocoaErrorDomain)
        XCTAssertEqual(error.code, 3840)
    }

    func test_responseSerialization_shouldBeSuccessful_whenDataIsValid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .success(let value) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value as? NSDictionary, ["foo": "bar", "baz": [123], "bar": ["baz": true]])
    }

    func test_responseSerialization_shouldBeSuccessful_whenOptionsAllowFragments() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "123".data(using: .utf8)

        // When
        let serializer = JSONResponseSerializer(options: .fragmentsAllowed)
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .success(let value) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value as? NSNumber, 123)
    }
}

// MARK: -

private enum TestError: Error {
    case foo
}

private extension Error {
    var domain: String {
        return (self as NSError).domain
    }

    var code: Int {
        return (self as NSError).code
    }
}
