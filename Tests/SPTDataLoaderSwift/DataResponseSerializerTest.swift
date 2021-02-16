/*
 Copyright (c) 2015-2021 Spotify AB.

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

class DataResponseSerializerTest: XCTestCase {
    func test_responseSerialization_shouldFail_whenErrorIsPresent() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseError = NSError(domain: "foo", code: 123, userInfo: nil)
        let responseFake = FakeDataLoaderResponse(request: request, error: responseError)

        // When
        let serializer = DataResponseSerializer()
        let result = Result { try serializer.serialize(response: responseFake) }

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure result")
        }
        XCTAssertEqual(error as NSError, responseError)
    }

    func test_responseSerialization_shouldBeSuccessful_whenBodyIsMissing() {
        // Given
        let request = SPTDataLoaderRequest()
        let responseFake = FakeDataLoaderResponse(request: request)

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
        let responseFake = FakeDataLoaderResponse(request: request, body: responseBody)

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
