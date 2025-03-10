// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class DecodableResponseSerializerTest: XCTestCase {

    func test_responseSerialization_shouldBeUnsuccessful_whenBodyIsMissing() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
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
        let responseBody = "{\"foo\": 123}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertTrue(error is DecodingError)
    }

    func test_responseSerialization_shouldBeSuccessful_whenBodyIsValid() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "{\"foo\": \"bar\"}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let decoder = JSONDecoder()
        let serializer = DecodableResponseSerializer<TestDecodable>(decoder: decoder)
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .success(let decodable) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(decodable.foo, "bar")
    }
}
