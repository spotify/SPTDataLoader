// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class DataResponseSerializerTest: XCTestCase {
    func test_responseSerialization_shouldBeSuccessful_whenBodyIsMissing() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let serializer = DataResponseSerializer()
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error as? ResponseSerializationError, .dataNotFound)
    }

    func test_responseSerialization_shouldBeSuccessful_whenBodyIsPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "foo".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let serializer = DataResponseSerializer()
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .success(let data) = result else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(data, responseBody)
    }
}
