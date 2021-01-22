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

import Foundation

typealias ResponseHandler = (Result<SPTDataLoaderResponse, Error>) -> Void
public typealias ResponseValidator = (SPTDataLoaderResponse) throws -> Void

/// A wrapper for initiating URL requests and handling responses with optional validation.
///
/// The `Request` type provides a set of functions that make it easy to chain a series of
/// response handlers and validators.
///
/// The request is executed upon attachment of the first response handler. If a handler is
/// attached after the response has been received, it will be immediately invoked with the
/// existing value.
public final class Request {
    private let request: SPTDataLoaderRequest
    private let executionHandler: () -> SPTDataLoaderCancellationToken?

    init(request: SPTDataLoaderRequest, executionHandler: @escaping () -> SPTDataLoaderCancellationToken?) {
        self.request = request
        self.executionHandler = executionHandler
    }

    private enum State {
        case initialized
        case executed(token: SPTDataLoaderCancellationToken)
        case completed(response: SPTDataLoaderResponse)
        case failed(error: Error)
        case cancelled
    }

    private let accessLock = AccessLock()
    private var state: State = .initialized
    private var responseHandlers: [ResponseHandler] = []
    private var responseValidators: [ResponseValidator] = []

    func addResponseValidator(_ responseValidator: @escaping ResponseValidator) {
        accessLock.sync {
            switch state {
            case .initialized, .executed:
                responseValidators.append(responseValidator)
            default:
                break
            }
        }
    }

    func addResponseHandler(_ responseHandler: @escaping ResponseHandler) {
        var result: Result<SPTDataLoaderResponse, Error>?

        accessLock.sync {
            switch state {
            case .initialized:
                if let token = executionHandler() {
                    responseHandlers.append(responseHandler)
                    state = .executed(token: token)
                } else {
                    result = .failure(RequestError.executionFailed)
                    state = .failed(error: RequestError.executionFailed)
                }
            case .executed:
                responseHandlers.append(responseHandler)
            case .failed(let error):
                result = .failure(error)
            case .completed(let response):
                result = .success(response)
            default:
                break
            }
        }

        result.map { result in responseHandler(result) }
    }

    func processResponse(_ response: SPTDataLoaderResponse) {
        var error = response.error
        var handlers: [ResponseHandler] = []

        accessLock.sync {
            guard case .executed = state else {
                return
            }

            if let error = error {
                state = .failed(error: error)
            } else {
                do {
                    try responseValidators.forEach { validator in try validator(response) }
                    state = .completed(response: response)
                } catch let validationError {
                    error = validationError
                    state = .failed(error: validationError)
                }
            }

            handlers = responseHandlers

            responseHandlers.removeAll()
            responseValidators.removeAll()
        }

        let result = Result { try error.map { error in throw error } ?? response }
        handlers.forEach { handler in handler(result) }
    }
}

// MARK: -

public extension Request {
    /// Modifies properties of the underlying request.
    /// - Parameter requestModifier: The modification closure used to mutate the request.
    @discardableResult
    func modify(requestModifier: (SPTDataLoaderRequest) -> Void) -> Self {
        accessLock.sync {
            guard case .initialized = state else {
                return
            }

            requestModifier(request)
        }

        return self
    }
}

// MARK: -

public extension Request {
    /// Cancels the current request.
    func cancel() {
        accessLock.sync {
            if case .executed(let token) = state {
                token.cancel()
            }

            state = .cancelled
        }
    }

    /// A Boolean value indicating whether the request has been cancelled.
    var isCancelled: Bool {
        return accessLock.sync {
            guard case .cancelled = state else {
                return false
            }

            return true
        }
    }
}

// MARK: -

public extension Request {
    /// Adds a validator used to verify a response.
    /// - Parameter responseValidator: The validation closure invoked upon response.
    @discardableResult
    func validate(responseValidator: @escaping ResponseValidator) -> Self {
        addResponseValidator(responseValidator)

        return self
    }
}

// MARK: -

public extension Request {
    /// Adds a handler that receives a `Response`.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func response(completionHandler: @escaping (Response<Void, Error>) -> Void) -> Self {
        addResponseHandler { [request] result in
            let response = Response(
                request: request,
                response: result.success,
                result: result.map { _ in () }
            )
            completionHandler(response)
        }

        return self
    }

    /// Adds a handler that receives a `Response` containing data.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func responseData(completionHandler: @escaping (Response<Data, Error>) -> Void) -> Self {
        addResponseHandler { [request] result in
            let response = Response(
                request: request,
                response: result.success,
                result: result.flatMap { response in
                    Result { try DataResponseSerializer().serialize(response: response) }
                }
            )
            completionHandler(response)
        }

        return self
    }

    /// Adds a handler that receives a `Response` containing a decoded value.
    /// - Parameter decoder: The `ResponseDecoder` used to decode the value from response data.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func responseDecodable<Value: Decodable>(
        decoder: ResponseDecoder = JSONDecoder(),
        completionHandler: @escaping (Response<Value, Error>) -> Void
    ) -> Self {
        addResponseHandler { [request] result in
            let response = Response(
                request: request,
                response: result.success,
                result: result.flatMap { response in
                    Result { try DecodableResponseSerializer<Value>(decoder: decoder).serialize(response: response) }
                }
            )
            completionHandler(response)
        }

        return self
    }

    /// Adds a handler that receives a `Response` containing a JSON value.
    /// - Parameter options: The `JSONSerialization.ReadingOptions` to use for reading the JSON response data.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func responseJSON(
        options: JSONSerialization.ReadingOptions = [],
        completionHandler: @escaping (Response<Any, Error>) -> Void
    ) -> Self {
        addResponseHandler { [request] result in
            let response = Response(
                request: request,
                response: result.success,
                result: result.flatMap { response in
                    Result { try JSONResponseSerializer(options: options).serialize(response: response) }
                }
            )
            completionHandler(response)
        }

        return self
    }

    /// Adds a handler that receives a `Response` containing a serialized value.
    /// - Parameter serializer: The `ResponseSerializer` to use for serializing the response value.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func responseSerializable<Serializer: ResponseSerializer>(
        serializer: Serializer,
        completionHandler: @escaping (Response<Serializer.Output, Error>) -> Void
    ) -> Self {
        addResponseHandler { [request] result in
            let response = Response(
                request: request,
                response: result.success,
                result: result.flatMap { response in
                    Result { try serializer.serialize(response: response) }
                }
            )
            completionHandler(response)
        }

        return self
    }
}
