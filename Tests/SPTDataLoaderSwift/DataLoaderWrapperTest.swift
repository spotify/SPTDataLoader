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
    private lazy var dataLoaderWrapper = DataLoaderWrapper(sptDataLoader: sptDataLoader)

    // MARK: Setup

    override func setUp() {
        super.setUp()

        sptDataLoader.delegate = dataLoaderWrapper
        stubbedNetwork.removeAllStubs()
    }

    // MARK: Cancellation Tests

    func test_dataLoaderRequest_shouldNotReceiveResponse_whenRequestIsCancelled() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result unexpected")
        responseExpectation.isInverted = true

        let token = dataLoaderWrapper.request(request) { (response: SPTDataLoaderResponse) in
            responseExpectation.fulfill()
        }
        token?.cancel()

        // Then
        waitForExpectations(timeout: 0.5)
    }

    // MARK: Response Tests

    func test_dataLoaderRequest_shouldReceiveResponse_whenResponseIsError() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addErrorStub(code: 123, where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: SPTDataLoaderResponse) in
            responseExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dataLoaderRequest_shouldReceiveResponse_whenResponseIsSuccess() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: SPTDataLoaderResponse) in
            responseExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    // MARK: Data Response Tests

    func test_dataLoaderRequestData_shouldReceiveResult_whenResponseIsError() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addErrorStub(code: 123, where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: Response<Data?, Error>) in
            if case .failure = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dataLoaderRequestData_shouldReceiveResult_whenResponseIsSuccess() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addStub(where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: Response<Data?, Error>) in
            if case .success = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    // MARK: Decodable Response Tests

    func test_dataLoaderRequestDecodable_shouldReceiveResult_whenResponseIsError() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addErrorStub(code: 123, where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: Response<TestDecodable, Error>) in
            if case .failure = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dataLoaderRequestDecodable_shouldReceiveResult_whenResponseIsSuccess() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addStub(
            body: "{\"foo\": \"bar\"}".data(using: .utf8),
            where: { $0.url == url }
        )

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: Response<TestDecodable, Error>) in
            if case .success = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    // MARK: JSON Response Tests

    func test_dataLoaderRequestJSON_shouldReceiveResult_whenResponseIsError() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addErrorStub(code: 123, where: { $0.url == url })

        // When
        let responseExpectation = expectation(description: "Error response expected")
        dataLoaderWrapper.request(request) { (response: Response<Any, Error>) in
            if case .failure = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func test_dataLoaderRequestJSON_shouldReceiveResult_whenResponseIsSuccess() {
        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        stubbedNetwork.addStub(
            body: "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8),
            where: { $0.url == url }
        )

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request) { (response: Response<Any, Error>) in
            if case .success = response.result {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }

    // MARK: Custom Serializer Response Tests

    func test_dataLoaderRequestSerializer_shouldReceiveResult_whenProvided() {
        struct Serializer: ResponseSerializer {
            func serialize(response: SPTDataLoaderResponse) -> String? {
                return response.body.flatMap { String(data: $0, encoding: .utf8) }
            }
        }

        // Given
        let url = URL(static: "https://foo.bar/baz.json")
        let request = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseSerializer = Serializer()

        stubbedNetwork.addStub(
            body: "foo".data(using: .utf8),
            where: { $0.url == url }
        )

        // When
        let responseExpectation = expectation(description: "Result expected")
        dataLoaderWrapper.request(request, serializer: responseSerializer) { (response: Response<String?, Error>) in
            if response.value == "foo" {
                responseExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: -

private enum TestError: Error {
    case foo
}

private struct TestDecodable: Decodable, Equatable {
    let foo: String
}

// MARK: -

extension URL {
    init(static string: StaticString) {
        guard let url = URL(string: string.description) else {
            fatalError("Invalid URL: \(string)")
        }

        self = url
    }
}
