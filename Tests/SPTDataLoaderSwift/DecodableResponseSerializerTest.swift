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

class DecodableResponseSerializerTest: XCTestCase {
    func test_responseSerialization_shouldBeUnsuccessful_whenErrorIsPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.error = TestError.foo

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
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
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertTrue(error is DecodingError)
    }

    func test_responseSerialization_shouldBeUnsuccessful_whenDataIsInvalid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "{\"foo\": 123}".data(using: .utf8)

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertTrue(error is DecodingError)
    }

    func test_responseSerialization_shouldBeSuccessful_whenDataIsValid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "{\"foo\": \"bar\"}".data(using: .utf8)

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
        let result = Result { try serializer.serialize(response: responseMock) }

        // Then
        guard case .success(let decodable) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(decodable.foo, "bar")
    }
}

// MARK: -

private enum TestError: Error {
    case foo
}

private struct TestDecodable: Decodable {
    let foo: String
}
