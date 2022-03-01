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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class Request_ResponseTaskTest: XCTestCase {
    private actor ResponseActor<Value> {
        var value: Value?

        func setValue(_ value: Value) {
            self.value = value
        }
    }

    private func process<TaskValue, ReturnValue>(
        request: Request,
        response: SPTDataLoaderResponse,
        taskProvider: @escaping (Request) -> ResponseTask<TaskValue>,
        valueProvider: @escaping (ResponseTask<TaskValue>) async -> ReturnValue
    ) async -> ReturnValue {
        let responseActor = ResponseActor<ReturnValue>()

        async let responseTask = Task(priority: .high) { () -> ReturnValue in
            let responseTask = taskProvider(request)
            let value = await valueProvider(responseTask)

            await responseActor.setValue(value)

            return value
        }

        while await responseActor.value == nil {
            request.processResponse(response)
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        return await responseTask.value
    }

    // MARK: Response Task

    func test_responseTask_shouldReceiveOutput_whenResponseIsPresent() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.task() },
            valueProvider: { await $0.response }
        )

        // Then
        guard case .success = response.result else {
            return XCTFail("Expected success result, got \(response.result)")
        }
        XCTAssertEqual(response.response, responseFake)
    }

    // MARK: Data Response Task

    func test_dataResponseTask_shouldReceiveOutput_whenSerializationProducesSuccess() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.dataTask() },
            valueProvider: { await $0.response }
        )

        // Then
        guard case .success = response.result else {
            return XCTFail("Expected success result, got \(response.result)")
        }
        XCTAssertEqual(response.response, responseFake)
    }

    // MARK: Decodable Response Task

    func test_decodableResponseTask_shouldReceiveOutput_whenSerializationProducesSuccess() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\"}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { request -> ResponseTask<TestDecodable> in request.decodableTask() },
            valueProvider: { await $0.response }
        )

        // Then
        guard case .success = response.result else {
            return XCTFail("Expected success result, got \(response.result)")
        }
        XCTAssertEqual(response.response, responseFake)
    }

    // MARK: JSON Response Task

    func test_jsonResponseTask_shouldReceiveOutput_whenSerializationProducesSuccess() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.jsonTask() },
            valueProvider: { await $0.response }
        )

        // Then
        guard case .success = response.result else {
            return XCTFail("Expected success result, got \(response.result)")
        }
        XCTAssertEqual(response.response, responseFake)
    }

    // MARK: Serializable Response Task

    func test_serializableResponseTask_shouldReceiveOutput_whenSerializationProducesSuccess() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.serializableTask(serializer: TestSerializer()) },
            valueProvider: { await $0.response }
        )

        // Then
        guard case .success = response.result else {
            return XCTFail("Expected success result, got \(response.result)")
        }
        XCTAssertEqual(response.response, responseFake)
    }

    // MARK: Response Value Task

    func test_responseValueTask_shouldThrowError_whenSerializationProducesFailure() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseFake = DataLoaderResponseFake(request: sptRequest)

        // When
        var responseError: Error?
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        _ = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.dataTask() },
            valueProvider: { task -> Data in
                do {
                    return try await task.value
                } catch {
                    responseError = error
                    return Data()
                }
            }
        )

        // Then
        XCTAssertNotNil(responseError)
    }

    func test_responseValueTask_shouldReceiveValue_whenSerializationProducesSuccess() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://foo.bar/baz.json"))
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: nil)
        let responseBody = "{\"foo\": \"bar\", \"baz\": [123], \"bar\": {\"baz\": true}}".data(using: .utf8)
        let responseFake = DataLoaderResponseFake(request: sptRequest, body: responseBody)

        // When
        var responseError: Error?
        let request = Request(request: sptRequest) { _ in CancellationTokenFake() }
        let response = await process(
            request: request,
            response: responseFake,
            taskProvider: { $0.dataTask() },
            valueProvider: { task -> Data in
                do {
                    return try await task.value
                } catch {
                    responseError = error
                    return Data()
                }
            }
        )

        // Then
        XCTAssertNil(responseError)
        XCTAssertEqual(response, responseBody)
    }
}

#endif
