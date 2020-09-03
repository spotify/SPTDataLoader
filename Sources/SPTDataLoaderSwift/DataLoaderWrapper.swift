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

/// A wrapper around `SPTDataLoader` that provides a closure-based
/// callback API without having to modify the request's userInfo.
final class DataLoaderWrapper: NSObject {
    private let sptDataLoader: SPTDataLoader
    private var responseHandlers: [Int64: (SPTDataLoaderResponse) -> Void] = [:]

    /// Initializes the data loader with the given `SPTDataLoader`.
    /// - Parameter sptDataLoader: The wrapped data loader object.
    init(sptDataLoader: SPTDataLoader) {
        self.sptDataLoader = sptDataLoader
    }

    /// Performs a request and provides the response to the given handler.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter responseHandler: The callback closure invoked upon response.
    @discardableResult
    func perform(
        _ request: SPTDataLoaderRequest,
        responseHandler: @escaping (SPTDataLoaderResponse) -> Void
    ) -> SPTDataLoaderCancellationToken? {
        responseHandlers[request.uniqueIdentifier] = responseHandler

        return sptDataLoader.perform(request)
    }
}

// MARK: - DataLoader

extension DataLoaderWrapper: DataLoader {
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
            let serializer = DataResponseSerializer()
            let serializerResult = Result { try serializer.serialize(response: response) }
            let completionResponse = Response(response: response, result: serializerResult)
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
            let completionResponse = Response(response: response, result: serializerResult)
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
            let completionResponse = Response(response: response, result: serializerResult)
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
            let completionResponse = Response(response: response, result: serializerResult)
            completionHandler(completionResponse)
        }
    }
}

// MARK: - SPTDataLoaderDelegate

extension DataLoaderWrapper: SPTDataLoaderDelegate {
    func dataLoader(_ dataLoader: SPTDataLoader, didReceiveSuccessfulResponse response: SPTDataLoaderResponse) {
        if let handler = responseHandlers.removeValue(forKey: response.request.uniqueIdentifier) {
            handler(response)
        }
    }

    public func dataLoader(_ dataLoader: SPTDataLoader, didReceiveErrorResponse response: SPTDataLoaderResponse) {
        if let handler = responseHandlers.removeValue(forKey: response.request.uniqueIdentifier) {
            handler(response)
        }
    }

    public func dataLoader(_ dataLoader: SPTDataLoader, didCancel request: SPTDataLoaderRequest) {
        responseHandlers.removeValue(forKey: request.uniqueIdentifier)
    }
}
