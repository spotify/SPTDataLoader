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

class DataLoaderWrapperTest: XCTestCase {
    private lazy var stubbedNetwork = StubbedNetwork()
    private lazy var sptDataLoader = stubbedNetwork.dataLoaderFactory.createDataLoader()
    private lazy var dataLoaderWrapper = DataLoaderWrapper(dataLoader: sptDataLoader)

    // MARK: Setup

    override func setUp() {
        super.setUp()

        sptDataLoader.delegate = dataLoaderWrapper
        sptDataLoader.delegateQueue = .main

        stubbedNetwork.removeAllStubs()
    }

    // MARK: Request Tests

    func test_request_shouldReceiveCallback_whenSuccessReceived() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let request = dataLoaderWrapper.request(url, sourceIdentifier: "foo")

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Response expected")
        request.response { _ in responseExpectation.fulfill() }

        // Then
        waitForExpectations(timeout: 0.5)
    }

    func test_request_shouldReceiveCallback_whenErrorReceived() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let request = dataLoaderWrapper.request(url, sourceIdentifier: "foo")

        stubbedNetwork.addErrorStub(code: 123, where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Response expected")
        request.response { _ in responseExpectation.fulfill() }

        // Then
        waitForExpectations(timeout: 0.5)
    }

    func test_request_shouldNotReceiveCallback_whenCancelled() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let request = dataLoaderWrapper.request(url, sourceIdentifier: "foo")

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Response not expected")
        responseExpectation.isInverted = true

        request
            .response { _ in responseExpectation.fulfill() }
            .cancel()

        // Then
        waitForExpectations(timeout: 0.5)
    }
}

// MARK: -

private enum TestError: Error {
    case foo
}
