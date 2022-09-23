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

import Foundation

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Request {
    func task() -> ResponseTask<Void> {
        return ResponseTask(request: self)
    }

    func dataTask() -> ResponseTask<Data> {
        return ResponseTask(request: self)
    }

    func decodableTask<Value: Decodable>(decoder: ResponseDecoder = JSONDecoder()) -> ResponseTask<Value> {
        return ResponseTask(request: self, decoder: decoder)
    }

    func jsonTask(options: JSONSerialization.ReadingOptions = []) -> ResponseTask<Any> {
        return ResponseTask(request: self, options: options)
    }

    func serializableTask<Serializer: ResponseSerializer>(serializer: Serializer) -> ResponseTask<Serializer.Output> {
        return ResponseTask(request: self, serializer: serializer)
    }
}

// MARK: -

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct ResponseTask<Value> {
    private let task: Task<Response<Value, Error>, Never>

    fileprivate init(
        request: Request,
        continuation: @escaping (CheckedContinuation<Response<Value, Error>, Never>) -> Void
    ) {
        self.task = Task {
            await withTaskCancellationHandler(
                operation: { await withCheckedContinuation(continuation) },
                onCancel: {
                    request.cancel()
                }
            )
        }
    }

    public func cancel() {
        task.cancel()
    }

    public var response: Response<Value, Error> {
        get async { await task.value }
    }

    public var result: Result<Value, Error> {
        get async { await response.result }
    }

    public var value: Value {
        get async throws { try await result.get() }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
private extension ResponseTask {
    init(request: Request) where Value == Void {
        self.init(request: request) { continuation in
            request.response { response in
                continuation.resume(returning: response)
            }
        }
    }

    init(request: Request) where Value == Data {
        self.init(request: request) { continuation in
            request.responseData { response in
                continuation.resume(returning: response)
            }
        }
    }

    init(request: Request, decoder: ResponseDecoder) where Value: Decodable {
        self.init(request: request) { continuation in
            request.responseDecodable(decoder: decoder) { response in
                continuation.resume(returning: response)
            }
        }
    }

    init(request: Request, options: JSONSerialization.ReadingOptions) where Value == Any {
        self.init(request: request) { continuation in
            request.responseJSON(options: options) { response in
                continuation.resume(returning: response)
            }
        }
    }

    init<Serializer: ResponseSerializer>(request: Request, serializer: Serializer) where Value == Serializer.Output {
        self.init(request: request) { continuation in
            request.responseSerializable(serializer: serializer) { response in
                continuation.resume(returning: response)
            }
        }
    }
}

#endif
