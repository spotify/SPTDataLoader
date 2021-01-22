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

class RequestTest: XCTestCase {
    // MARK: Modification

    func test_request_shouldBeModified_whenInitialized() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        request.modify { $0.method = .delete }

        // Then
        XCTAssertEqual(sptRequest.method, .delete)
    }

    func test_request_shouldNotBeModified_whenExecuted() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        request.addResponseHandler { _ in }
        request.modify { $0.method = .delete }

        // Then
        XCTAssertEqual(sptRequest.method, .get)
    }

    // MARK: Cancellation

    func test_request_shouldBeCancelled_whenRequested() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let cancellationTokenMock = CancellationTokenFake()

        let request = Request(request: sptRequest) {
            return cancellationTokenMock
        }

        // When
        request.addResponseHandler { _ in }
        request.cancel()

        // Then
        XCTAssertTrue(request.isCancelled)
        XCTAssertTrue(cancellationTokenMock.isCancelled)
    }

    // MARK: Response Validators

    func test_responseValidator_shouldNotExecute_whenResponseContainsError() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        var validatorCount = 0
        var result: Result<SPTDataLoaderResponse, Error>?
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseHandler { result = $0 }
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(validatorCount, 0)
    }

    func test_responseValidator_shouldExecute_whenErrorIsAbsent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        var validatorCount = 0
        var result: Result<SPTDataLoaderResponse, Error>?
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseHandler { result = $0 }
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(validatorCount, 2)
    }

    func test_responseValidator_shouldStopValidation_whenErrorOccurs() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        var validatorCount = 0
        var result: Result<SPTDataLoaderResponse, Error>?
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseValidator { _ in throw TestError.foo }
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseHandler { result = $0 }
        request.processResponse(responseFake)

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected error result, got \(String(describing: result))")
        }
        guard let testError = error as? TestError else {
            return XCTFail("Expected TestError, got \(type(of: error))")
        }
        XCTAssertEqual(testError, .foo)
        XCTAssertEqual(validatorCount, 1)
    }

    // MARK: Response Processing

    func test_responseHandler_shouldReceiveError_whenRequestExecutionFails() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) {
            return nil
        }

        // When
        var result: Result<SPTDataLoaderResponse, Error>?
        request.addResponseHandler { result = $0 }
        request.processResponse(responseFake)

        // Then
        guard case .failure(let error) = result else {
            return XCTFail("Expected error result, got \(String(describing: result))")
        }
        guard case .executionFailed = error as? RequestError else {
            return XCTFail("Expected RequestError.executionFailed, got \(error)")
        }
    }

    func test_responseHandler_shouldNotExecute_whenRequestIsCancelled() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        var responseCount = 0
        request.addResponseHandler { _ in responseCount += 1 }
        request.cancel()
        request.processResponse(responseFake)

        // Then
        XCTAssertEqual(responseCount, 0)
    }

    func test_responseHandler_shouldNotExecute_whenAlreadyProcessed() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) {
            return CancellationTokenFake()
        }

        // When
        var responseCount = 0
        request.addResponseHandler { _ in responseCount += 1 }
        request.processResponse(responseFake)
        request.processResponse(responseFake)

        // Then
        XCTAssertEqual(responseCount, 1)
    }

    func test_responseHandler_shouldExecute_whenAddedBeforeCompletion() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        var requestCount = 0
        let request = Request(request: sptRequest) {
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var result1: Result<SPTDataLoaderResponse, Error>?
        var result2: Result<SPTDataLoaderResponse, Error>?
        request.addResponseHandler { result1 = $0 }
        request.addResponseHandler { result2 = $0 }
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(requestCount, 1)
    }

    func test_responseHandler_shouldExecute_whenAddedAfterFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        var requestCount = 0
        let request = Request(request: sptRequest) {
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var result1: Result<SPTDataLoaderResponse, Error>?
        var result2: Result<SPTDataLoaderResponse, Error>?
        request.addResponseHandler { result1 = $0 }
        request.processResponse(responseFake)
        request.addResponseHandler { result2 = $0 }

        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(requestCount, 1)
    }

    func test_responseHandler_shouldExecute_whenAddedAfterCompletion() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        var requestCount = 0
        let request = Request(request: sptRequest) {
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var result1: Result<SPTDataLoaderResponse, Error>?
        var result2: Result<SPTDataLoaderResponse, Error>?
        request.addResponseHandler { result1 = $0 }
        request.processResponse(responseFake)
        request.addResponseHandler { result2 = $0 }

        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(requestCount, 1)
    }

    // MARK: Response Handler

    func test_responseHandler_shouldReceiveFailure_whenErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.validate { _ in
            throw TestError.foo
        }.response {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_responseHandler_shouldReceiveSuccess_whenResponseIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.response {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
    }


    // MARK: Data Response Handler

    func test_dataResponseHandler_shouldReceiveError_whenResponseContainsError() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseData {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_dataResponseHandler_shouldReceiveError_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseData {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_dataResponseHandler_shouldReceiveValue_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "foo".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseData {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
    }

    // MARK: Decodable Response Handler

    func test_decodableResponseHandler_shouldReceiveFailure_whenErrorPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.validate { _ in
            throw TestError.foo
        }.responseDecodable {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_decodableResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseDecodable {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_decodableResponseHandler_shouldReceiveSuccess_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\"}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseDecodable {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
    }

    // MARK: JSON Response Handler

    func test_jsonResponseHandler_shouldReceiveFailure_whenErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.validate { _ in
            throw TestError.foo
        }.responseJSON {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_jsonResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "bad".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseJSON {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_jsonResponseHandler_shouldReceiveValue_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseJSON {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
    }

    // MARK: Serializable Response Handler

    func test_serializableResponseHandler_shouldReceiveFailure_whenErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.validate { _ in
            throw TestError.foo
        }.responseSerializable(serializer: TestSerializer()) {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_serializableResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseSerializable(serializer: TestSerializer()) {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .failure = actualResponse.result else {
            return XCTFail("Expected error result, got \(actualResponse.result)")
        }
    }

    func test_serializableResponseHandler_shouldReceiveSuccess_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) {
            return CancellationTokenFake()
        }.responseSerializable(serializer: TestSerializer()) {
            response = $0
        }.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
    }
}

// MARK: -

private enum TestError: Error {
    case foo
    case bar
}

private struct TestDecodable: Decodable, Equatable {
    let foo: String
}

private struct TestSerializer: ResponseSerializer {
    func serialize(response: SPTDataLoaderResponse) throws -> String {
        guard let data = response.body else {
            throw TestError.foo
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw TestError.foo
        }

        return string
    }
}

// MARK: -

private final class CancellationTokenFake: NSObject, SPTDataLoaderCancellationToken {
    var isCancelled: Bool = false
    var objectToCancel: Any?

    weak var delegate: SPTDataLoaderCancellationTokenDelegate?

    func cancel() {
        isCancelled = true
    }
}
