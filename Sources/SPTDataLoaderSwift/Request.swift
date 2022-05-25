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

import Foundation

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
    private let executionHandler: (Request) -> SPTDataLoaderCancellationToken?

    init(request: SPTDataLoaderRequest, executionHandler: @escaping (Request) -> SPTDataLoaderCancellationToken?) {
        self.request = request
        self.executionHandler = executionHandler
    }

    private enum State {
        case initialized
        case failed(error: Error)
        case executed(token: SPTDataLoaderCancellationToken)
        case completed(response: SPTDataLoaderResponse)
        case completedWithError(response: SPTDataLoaderResponse, error: Error)
        case cancelled
    }

    enum ResponseState {
        case failed(error: Error)
        case completed(response: SPTDataLoaderResponse)
        case completedWithError(response: SPTDataLoaderResponse, error: Error)

        var response: SPTDataLoaderResponse? {
            switch self {
            case .completed(let response), .completedWithError(let response, _):
                return response
            case .failed:
                return nil
            }
        }

        var result: Result<SPTDataLoaderResponse, Error> {
            switch self {
            case .completed(let response):
                return .success(response)
            case .completedWithError(_, let error), .failed(let error):
                return .failure(error)
            }
        }
    }

    private let accessLock = AccessLock()
    private var state: State = .initialized
    private var responseHandlers: [(ResponseState) -> Void] = []
    private var responseValidators: [(SPTDataLoaderResponse) throws -> Void] = []

    func addResponseValidator(_ responseValidator: @escaping (SPTDataLoaderResponse) throws -> Void) {
        accessLock.sync {
            switch state {
            case .initialized, .executed:
                responseValidators.append(responseValidator)
            default:
                break
            }
        }
    }

    func addResponseHandler(_ responseHandler: @escaping (ResponseState) -> Void) {
        var responseState: ResponseState?

        accessLock.sync {
            switch state {
            case .initialized:
                if let token = executionHandler(self) {
                    responseHandlers.append(responseHandler)
                    state = .executed(token: token)
                } else {
                    responseState = .failed(error: RequestError.executionFailed)
                    state = .failed(error: RequestError.executionFailed)
                }
            case .executed:
                responseHandlers.append(responseHandler)
            case .failed(let error):
                responseState = .failed(error: error)
            case .completed(let response):
                responseState = .completed(response: response)
            case .completedWithError(let response, let error):
                responseState = .completedWithError(response: response, error: error)
            case .cancelled:
                break
            }
        }

        responseState.map { responseState in responseHandler(responseState) }
    }

    func processResponse(_ response: SPTDataLoaderResponse) {
        var handlers: [(ResponseState) -> Void] = []
        var responseState: ResponseState = .completed(response: response)

        accessLock.sync {
            guard case .executed = state else {
                return
            }

            // Respect any previous error except the one `SPTDataLoaderResponse` sets
            // based on status code, which should instead be enforced using a validator.
            if let error = response.error, (error as NSError).domain != SPTDataLoaderResponseErrorDomain {
                responseState = .completedWithError(response: response, error: error)
                state = .completedWithError(response: response, error: error)
            } else {
                do {
                    try responseValidators.forEach { validator in try validator(response) }
                    state = .completed(response: response)
                } catch let validationError {
                    responseState = .completedWithError(response: response, error: validationError)
                    state = .completedWithError(response: response, error: validationError)
                }
            }

            handlers = responseHandlers

            responseHandlers.removeAll()
            responseValidators.removeAll()
        }

        handlers.forEach { handler in handler(responseState) }
    }
}

// MARK: -

public extension Request {
    /// Modifies properties of the underlying request.
    /// - Parameter requestModifier: The modification closure used to mutate the request.
    @discardableResult
    func modify(requestModifier: (SPTDataLoaderRequest) throws -> Void) rethrows -> Self {
        try accessLock.sync {
            guard case .initialized = state else {
                return
            }

            try requestModifier(request)
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
    func validate(responseValidator: @escaping (SPTDataLoaderResponse) throws -> Void) -> Self {
        addResponseValidator(responseValidator)

        return self
    }

    /// Adds a validator used to verify a response status code.
    /// - Parameter acceptedStatusCodes: The accepted status codes.
    @discardableResult
    func validateStatusCode<StatusCodes: Sequence>(
        in acceptedStatusCodes: StatusCodes
    ) -> Self where StatusCodes.Iterator.Element == Int {
        addResponseValidator { response in
            guard acceptedStatusCodes.contains(response.statusCode.rawValue) else {
                throw ResponseValidationError.badStatusCode(code: response.statusCode.rawValue)
            }
        }

        return self
    }

    /// Adds a validator used to verify a response status code.
    /// - Parameter acceptedStatusCodes: The accepted status codes.
    @discardableResult
    func validateStatusCode(in acceptedStatusCodes: Int...) -> Self {
        return validateStatusCode(in: acceptedStatusCodes)
    }

    /// Adds a validator used to verify a response status code is in the successful 2xx range.
    /// - Parameter acceptedStatusCodes: The accepted status codes.
    @discardableResult
    func validateStatusCode() -> Self {
        return validateStatusCode(in: 200...299)
    }
}

// MARK: -

public extension Request {
    /// Adds a handler that receives a `Response`.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func response(completionHandler: @escaping (Response<Void, Error>) -> Void) -> Self {
        addResponseHandler { [request] state in
            let response = Response(
                request: request,
                response: state.response,
                result: state.result.map { _ in () }
            )
            completionHandler(response)
        }

        return self
    }

    /// Adds a handler that receives a `Response` containing data.
    /// - Parameter completionHandler: The callback closure invoked upon completion.
    @discardableResult
    func responseData(completionHandler: @escaping (Response<Data, Error>) -> Void) -> Self {
        addResponseHandler { [request] state in
            let response = Response(
                request: request,
                response: state.response,
                result: state.result.flatMap { response in
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
        addResponseHandler { [request] state in
            let response = Response(
                request: request,
                response: state.response,
                result: state.result.flatMap { response in
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
        addResponseHandler { [request] state in
            let response = Response(
                request: request,
                response: state.response,
                result: state.result.flatMap { response in
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
        addResponseHandler { [request] state in
            let response = Response(
                request: request,
                response: state.response,
                result: state.result.flatMap { response in
                    Result { try serializer.serialize(response: response) }
                }
            )
            completionHandler(response)
        }

        return self
    }
}
