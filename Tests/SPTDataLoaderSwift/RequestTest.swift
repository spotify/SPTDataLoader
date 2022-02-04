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

class RequestTest: XCTestCase {
    // MARK: Modification

    func test_request_shouldBeModified_whenInitialized() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        let request = Request(request: sptRequest) { _ in
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

        let request = Request(request: sptRequest) { _ in
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

        let request = Request(request: sptRequest) { _ in
            return cancellationTokenMock
        }

        // When
        request.addResponseHandler { _ in }
        request.cancel()

        // Then
        XCTAssertTrue(request.isCancelled)
        XCTAssertTrue(cancellationTokenMock.isCancelled)
    }

    // MARK: Execution

    func test_executionHandler_shouldReceiveRequestInstance_whenCalled() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)

        // When
        var executedRequest: Request?
        let request = Request(request: sptRequest) { request in
            executedRequest = request
            return CancellationTokenFake()
        }
        request.addResponseHandler { _ in }

        // Then
        XCTAssertTrue(request === executedRequest)
    }

    // MARK: Response Validators

    func test_responseValidator_shouldExecute_whenResponseErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }

        // When
        var validatorCount = 0
        var responseState: Request.ResponseState?
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseHandler { responseState = $0 }
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(responseState)
        XCTAssertEqual(validatorCount, 2)
    }

    func test_responseValidator_shouldStopValidation_whenErrorOccurs() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }

        // When
        var validatorCount = 0
        var responseState: Request.ResponseState?
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseValidator { _ in throw TestError.foo }
        request.addResponseValidator { _ in validatorCount += 1 }
        request.addResponseHandler { responseState = $0 }
        request.processResponse(responseFake)

        // Then
        guard case .completedWithError(let response, let error) = responseState else {
            return XCTFail("Expected error result, got \(String(describing: responseState))")
        }
        guard let testError = error as? TestError else {
            return XCTFail("Expected TestError, got \(type(of: error))")
        }
        XCTAssertEqual(response, responseFake)
        XCTAssertEqual(testError, .foo)
        XCTAssertEqual(validatorCount, 1)
    }

    // MARK: Response Processing

    func test_responseHandler_shouldReceiveError_whenRequestExecutionFails() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) { _ in
            return nil
        }

        // When
        var responseState: Request.ResponseState?
        request.addResponseHandler { responseState = $0 }
        request.processResponse(responseFake)
        request.addResponseHandler { responseState = $0 }

        // Then
        guard case .failed(let error) = responseState else {
            return XCTFail("Expected error result, got \(String(describing: responseState))")
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

        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }

        // When
        var responseCount = 0
        request.addResponseHandler { _ in responseCount += 1 }
        request.cancel()
        request.addResponseHandler { _ in responseCount += 1 }
        request.processResponse(responseFake)

        // Then
        XCTAssertEqual(responseCount, 0)
    }

    func test_responseHandler_shouldNotExecute_whenAlreadyProcessed() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        let request = Request(request: sptRequest) { _ in
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
        let request = Request(request: sptRequest) { _ in
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var responseState1: Request.ResponseState?
        var responseState2: Request.ResponseState?
        request.addResponseHandler { responseState1 = $0 }
        request.addResponseHandler { responseState2 = $0 }
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(responseState1)
        XCTAssertNotNil(responseState2)
        XCTAssertEqual(requestCount, 1)
    }

    func test_responseHandler_shouldExecute_whenAddedAfterCompletion() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        var requestCount = 0
        let request = Request(request: sptRequest) { _ in
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var responseState1: Request.ResponseState?
        var responseState2: Request.ResponseState?
        request.addResponseHandler { responseState1 = $0 }
        request.processResponse(responseFake)
        request.addResponseHandler { responseState2 = $0 }

        // Then
        XCTAssertNotNil(responseState1)
        XCTAssertNotNil(responseState2)
        XCTAssertEqual(requestCount, 1)
    }

    func test_responseHandler_shouldExecute_whenAddedAfterCompletionWithError() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        var requestCount = 0
        let request = Request(request: sptRequest) { _ in
            requestCount += 1
            return CancellationTokenFake()
        }

        // When
        var responseState1: Request.ResponseState?
        var responseState2: Request.ResponseState?
        request.addResponseHandler { responseState1 = $0 }
        request.processResponse(responseFake)
        request.addResponseHandler { responseState2 = $0 }

        // Then
        XCTAssertNotNil(responseState1)
        XCTAssertNotNil(responseState2)
        XCTAssertEqual(requestCount, 1)
    }

    // MARK: Response Handler

    func test_responseHandler_shouldReceiveFailure_whenExecutionErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) { _ in
            return nil
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
        XCTAssertNil(actualResponse.response)
    }

    func test_responseHandler_shouldReceiveFailure_whenValidationErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_responseHandler_shouldReceiveFailure_whenNonStatusCodeErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) { _ in
            return CancellationTokenFake()
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_responseHandler_shouldReceiveSuccess_whenStatusCodeErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let statusCodeError = NSError(domain: SPTDataLoaderResponseErrorDomain, code: 403, userInfo: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: statusCodeError)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_responseHandler_shouldReceiveSuccess_whenResponseIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Void, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    // MARK: Data Response Handler

    func test_dataResponseHandler_shouldReceiveError_whenResponseContainsError() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_dataResponseHandler_shouldReceiveError_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_dataResponseHandler_shouldReceiveValue_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "foo".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Data, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    // MARK: Decodable Response Handler

    func test_decodableResponseHandler_shouldReceiveFailure_whenErrorPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_decodableResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_decodableResponseHandler_shouldReceiveSuccess_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\"}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<TestDecodable, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    // MARK: JSON Response Handler

    func test_jsonResponseHandler_shouldReceiveFailure_whenErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_jsonResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "bad".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_jsonResponseHandler_shouldReceiveValue_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<Any, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    // MARK: Serializable Response Handler

    func test_serializableResponseHandler_shouldReceiveFailure_whenErrorIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, error: TestError.foo)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_serializableResponseHandler_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = FakeDataLoaderResponse(request: sptRequest)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
    }

    func test_serializableResponseHandler_shouldReceiveSuccess_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = FakeDataLoaderResponse(request: sptRequest, body: responseBody)

        // When
        var response: Response<String, Error>?
        Request(request: sptRequest) { _ in
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
        XCTAssertNotNil(actualResponse.response)
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
