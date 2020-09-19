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

final class DataLoaderWrapper: NSObject {
    private typealias ResponseHandler = (SPTDataLoaderResponse) -> Void

    private let dataLoader: SPTDataLoader

    private var requests: [Int64: Request] = [:]
    private var responseHandlers: [Int64: ResponseHandler] = [:]

    private let accessLock = DispatchQueue(label: "SPTDataLoader.DataLoaderWrapper")

    init(dataLoader: SPTDataLoader) {
        self.dataLoader = dataLoader
    }

    /// Performs a request and provides the response to the given handler.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter responseHandler: The callback closure invoked upon response.
    @discardableResult
    func perform(
        _ request: SPTDataLoaderRequest,
        responseHandler: @escaping (SPTDataLoaderResponse) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        accessLock.sync {
            responseHandlers[request.uniqueIdentifier] = responseHandler
        }

        return dataLoader.perform(request)
    }
}

// MARK: - DataLoader

extension DataLoaderWrapper: DataLoader {
    func request(_ url: URL, sourceIdentifier: String?) -> Request {
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: sourceIdentifier)
        let request = Request(request: sptRequest) { [dataLoader] in
            return dataLoader.perform(sptRequest)
        }

        accessLock.sync {
            requests[sptRequest.uniqueIdentifier] = request
        }

        return request
    }

    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        completionHandler: @escaping (SPTDataLoaderResponse) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        return perform(request, responseHandler: completionHandler)
    }

    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        completionHandler: @escaping (Response<Data?, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        return perform(request) { response in
            let serializer = OptionalDataResponseSerializer()
            let serializerResult = Result { try serializer.serialize(response: response) }
            let completionResponse = Response(request: request, response: response, result: serializerResult)
            completionHandler(completionResponse)
        }
    }

    @discardableResult
    func request<Value: Decodable>(
        _ request: SPTDataLoaderRequest,
        decoder: ResponseDecoder = JSONDecoder(),
        completionHandler: @escaping (Response<Value, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        return perform(request) { response in
            let serializer = DecodableResponseSerializer<Value>(decoder: decoder)
            let serializerResult = Result { try serializer.serialize(response: response) }
            let completionResponse = Response(request: request, response: response, result: serializerResult)
            completionHandler(completionResponse)
        }
    }

    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        options: JSONSerialization.ReadingOptions = [],
        completionHandler: @escaping (Response<Any, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        return perform(request) { response in
            let serializer = JSONResponseSerializer(options: options)
            let serializerResult = Result { try serializer.serialize(response: response) }
            let completionResponse = Response(request: request, response: response, result: serializerResult)
            completionHandler(completionResponse)
        }
    }

    @discardableResult
    func request<Serializer: ResponseSerializer>(
        _ request: SPTDataLoaderRequest,
        serializer: Serializer,
        completionHandler: @escaping (Response<Serializer.Output, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        return perform(request) { response in
            let serializerResult = Result { try serializer.serialize(response: response) }
            let completionResponse = Response(request: request, response: response, result: serializerResult)
            completionHandler(completionResponse)
        }
    }
}

// MARK: - SPTDataLoaderDelegate

extension DataLoaderWrapper: SPTDataLoaderDelegate {
    func dataLoader(_ dataLoader: SPTDataLoader, didReceiveSuccessfulResponse response: SPTDataLoaderResponse) {
        handleResponse(response)
    }

    func dataLoader(_ dataLoader: SPTDataLoader, didReceiveErrorResponse response: SPTDataLoaderResponse) {
        handleResponse(response)
    }

    func dataLoader(_ dataLoader: SPTDataLoader, didCancel request: SPTDataLoaderRequest) {
        accessLock.sync {
            requests[request.uniqueIdentifier] = nil
            responseHandlers[request.uniqueIdentifier] = nil
        }
    }

    private func handleResponse(_ response: SPTDataLoaderResponse) {
        var request: Request?
        var responseHandler: ResponseHandler?

        accessLock.sync {
            request = requests.removeValue(forKey: response.request.uniqueIdentifier)
            responseHandler = responseHandlers.removeValue(forKey: response.request.uniqueIdentifier)
        }

        request.map { request in request.processResponse(response) }
        responseHandler.map { responseHandler in responseHandler(response) }
    }
}
