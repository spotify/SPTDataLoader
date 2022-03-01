// Copyright 2015-2022 Spotify AB
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

    // MARK: Active Tests

    func test_activeRequests_shouldProvideExecutingRequests_whenRequested() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let request1 = dataLoaderWrapper.request(url, sourceIdentifier: "foo")
        let request2 = dataLoaderWrapper.request(url, sourceIdentifier: "bar")
        let request3 = dataLoaderWrapper.request(url, sourceIdentifier: "baz")

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        request1.response { _ in }
        request2.response { _ in }
        let requests = dataLoaderWrapper.activeRequests

        // Then
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests.contains(where: { $0 === request1 }))
        XCTAssertTrue(requests.contains(where: { $0 === request2 }))
        XCTAssertFalse(requests.contains(where: { $0 === request3 }))
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

    // MARK: Cancel Tests

    func test_cancelActiveRequests_shouldNotReceiveCallbacks_whenExecuted() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let request1 = dataLoaderWrapper.request(url, sourceIdentifier: "foo")
        let request2 = dataLoaderWrapper.request(url, sourceIdentifier: "bar")
        let request3 = dataLoaderWrapper.request(url, sourceIdentifier: "baz")

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Response not expected")
        responseExpectation.isInverted = true

        request1.response { _ in responseExpectation.fulfill() }
        request2.response { _ in responseExpectation.fulfill() }
        dataLoaderWrapper.cancelActiveRequests()

        // Then
        waitForExpectations(timeout: 0.5) { _ in
            XCTAssertTrue(request1.isCancelled)
            XCTAssertTrue(request2.isCancelled)
            XCTAssertFalse(request3.isCancelled)
        }
    }
}
