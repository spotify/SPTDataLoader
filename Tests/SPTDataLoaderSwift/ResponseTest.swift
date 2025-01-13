// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class ResponseTest: XCTestCase {
    func test_response_shouldProvideRequest_whenRequested() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let response = Response(request: request, response: responseFake, result: Result { true })

        // Given
        XCTAssertEqual(response.request, request)
    }

    func test_response_shouldProvideUnderlyingResponse_whenRequested() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let response = Response(request: request, response: responseFake, result: Result { true })

        // Given
        XCTAssertEqual(response.response, responseFake)
    }

    func test_response_shouldProvideData_whenPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseBody = "foo".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: request, body: responseBody)

        // When
        let response = Response(request: request, response: responseFake, result: Result { true })

        // Given
        XCTAssertEqual(response.data, responseBody)
    }

    func test_response_shouldProvideValue_whenResultIsSuccess() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let response = Response(request: request, response: responseFake, result: Result { true })

        // Given
        XCTAssertNil(response.error)
        XCTAssertEqual(response.value, true)
    }

    func test_response_shouldProvideError_whenResultIsFailure() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = DataLoaderResponseFake(request: request)

        // When
        let response = Response(request: request, response: responseFake, result: Result { throw TestError.foo })

        // Given
        XCTAssertNil(response.value)
        XCTAssertTrue(response.error is TestError)
    }
}
