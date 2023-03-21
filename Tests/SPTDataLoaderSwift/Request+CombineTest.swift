// Copyright 2015-2023 Spotify AB
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

#if canImport(Combine)

@testable import SPTDataLoaderSwift

import Combine
import Foundation
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class Request_ResponsePublisherTest: XCTestCase {
    // MARK: Response Publisher

    func test_responsePublisher_shouldReceiveOutput_whenResponseIsPresent() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var response: Response<Void, Error>?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.publisher().sink { response = $0 }.store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
        XCTAssertEqual(actualResponse.response, responseFake)
    }

    // MARK: Data Response Publisher

    func test_dataResponsePublisher_shouldReceiveOutput_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var response: Response<Data, Error>?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.dataPublisher().sink { response = $0 }.store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
        XCTAssertEqual(actualResponse.response, responseFake)
    }

    // MARK: Decodable Response Publisher

    func test_decodableResponsePublisher_shouldReceiveOutput_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\"}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var response: Response<TestDecodable, Error>?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.decodablePublisher().sink { response = $0 }.store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
        XCTAssertEqual(actualResponse.response, responseFake)
    }

    // MARK: JSON Response Publisher

    func test_jsonResponsePublisher_shouldReceiveOutput_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var response: Response<Any, Error>?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.jsonPublisher().sink { response = $0 }.store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
        XCTAssertEqual(actualResponse.response, responseFake)
    }

    // MARK: Serializable Response Publisher

    func test_serializableResponsePublisher_shouldReceiveOutput_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var response: Response<String, Error>?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.serializablePublisher(serializer: TestSerializer()).sink { response = $0 }.store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        guard let actualResponse = response else {
            return XCTFail("Expected response")
        }
        guard case .success = actualResponse.result else {
            return XCTFail("Expected success result, got \(actualResponse.result)")
        }
        XCTAssertEqual(actualResponse.response, responseFake)
    }

    // MARK: Response Value Publisher

    func test_responseValuePublisher_shouldReceiveFailure_whenSerializationProducesFailure() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = DataLoaderResponseFake(request: sptRequest)

        // When
        var cancellables: [AnyCancellable] = []
        var responseError: Error?
        var responseValue: Data?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.dataPublisher().valuePublisher().sink(
            receiveCompletion: { if case .failure(let error) = $0 { responseError = error } },
            receiveValue: { responseValue = $0 }
        ).store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        XCTAssertNotNil(responseError)
        XCTAssertNil(responseValue)
    }

    func test_responseValuePublisher_shouldReceiveOutput_whenSerializationProducesSuccess() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var cancellables: [AnyCancellable] = []
        var responseError: Error?
        var responseValue: Data?
        let request = Request(request: sptRequest) { _ in
            return CancellationTokenFake()
        }
        request.dataPublisher().valuePublisher().sink(
            receiveCompletion: { if case .failure(let error) = $0 { responseError = error } },
            receiveValue: { responseValue = $0 }
        ).store(in: &cancellables)
        request.processResponse(responseFake)

        // Then
        XCTAssertNil(responseError)
        XCTAssertEqual(responseValue, responseBody)
    }
}

#endif
