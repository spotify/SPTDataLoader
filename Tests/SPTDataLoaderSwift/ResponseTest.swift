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

class ResponseTest: XCTestCase {
    func test_response_shouldProvideUnderlyingResponse_whenRequested() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        // When
        let response = Response(response: responseMock, result: Result { true })

        // Given
        XCTAssertEqual(response.response, responseMock)
    }

    func test_response_shouldProvideRequest_whenRequested() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        // When
        let response = Response(response: responseMock, result: Result { true })

        // Given
        XCTAssertEqual(response.request, request)
    }

    func test_response_shouldProvideData_whenPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        responseMock.body = "foo".data(using: .utf8)

        // When
        let response = Response(response: responseMock, result: Result { true })

        // Given
        XCTAssertEqual(response.data, responseMock.body)
    }

    func test_response_shouldProvideValue_whenResultIsSuccess() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        // When
        let response = Response(response: responseMock, result: Result { true })

        // Given
        XCTAssertNil(response.error)
        XCTAssertEqual(response.value, true)
    }

    func test_response_shouldProvideError_whenResultIsFailure() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseMock = SPTDataLoaderResponse(request: request, response: nil)

        // When
        let response = Response(response: responseMock, result: Result { throw TestError.foo })

        // Given
        XCTAssertNil(response.value)
        XCTAssertTrue(response.error is TestError)
    }
}

// MARK: -

private enum TestError: Error {
    case foo
}
