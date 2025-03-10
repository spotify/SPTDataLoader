// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class JSONResponseSerializerTest: XCTestCase {
    func test_responseSerialization_shouldBeUnsuccessful_whenBodyIsMissing() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error as? ResponseSerializationError, .dataNotFound)
    }

    func test_responseSerialization_shouldBeUnsuccessful_whenBodyIsInvalid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "{null}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error.domain, NSCocoaErrorDomain)
        XCTAssertEqual(error.code, 3840)
    }

    func test_responseSerialization_shouldBeSuccessful_whenBodyIsValid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let serializer = JSONResponseSerializer(options: [])
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .success(let value) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value as? NSDictionary, ["foo": "bar", "baz": [123], "bar": ["baz": true]])
    }

    func test_responseSerialization_shouldSucceed_whenOptionsAllowFragments() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "123".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let serializer = JSONResponseSerializer(options: .fragmentsAllowed)
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .success(let value) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value as? NSNumber, 123)
    }
}
