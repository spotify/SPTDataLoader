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

/// A protocol that provides data request handling.
public protocol DataLoader {
    /// Performs a request and provides a `SPTDataLoaderResponse`.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter completionHandler: The callback closure invoked upon response.
    /// - Returns: A token capable of cancelling the request, or `nil` if the request is invalid.
    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        completionHandler: @escaping (SPTDataLoaderResponse) -> Void
    ) -> SPTDataLoaderCancellationToken?

    /// Performs a request and provides a `Response` containing the optional response data.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter completionHandler: The callback closure invoked upon response.
    /// - Returns: A token capable of cancelling the request, or `nil` if the request is invalid.
    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        completionHandler: @escaping (Response<Data?, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken?

    /// Performs a request and provides a `Response` containing a decoded value.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter decoder: The `ResponseDecoder` used to decode the value from response data.
    /// - Parameter completionHandler: The callback closure invoked upon response.
    /// - Returns: A token capable of cancelling the request, or `nil` if the request is invalid.
    @discardableResult
    func request<Value: Decodable>(
        _ request: SPTDataLoaderRequest,
        decoder: ResponseDecoder,
        completionHandler: @escaping (Response<Value, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken?

    /// Performs a request and provides a `Response` containing a JSON value.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter options: The `JSONSerialization.ReadingOptions` to use for reading the JSON response data.
    /// - Parameter completionHandler: The callback closure invoked upon response.
    /// - Returns: A token capable of cancelling the request, or `nil` if the request is invalid.
    @discardableResult
    func request(
        _ request: SPTDataLoaderRequest,
        options: JSONSerialization.ReadingOptions,
        completionHandler: @escaping (Response<Any, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken?

    /// Performs a request and provides a `Response` containing a serialized value.
    /// - Parameter request: The `SPTDataLoaderRequest` to perform.
    /// - Parameter serializer: The `ResponseSerializer` to use for serializing the response value.
    /// - Parameter completionHandler: The callback closure invoked upon response.
    /// - Returns: A token capable of cancelling the request, or `nil` if the request is invalid.
    @discardableResult
    func request<Serializer: ResponseSerializer>(
        _ request: SPTDataLoaderRequest,
        serializer: Serializer,
        completionHandler: @escaping (Response<Serializer.Output, Error>) -> Void
    ) -> SPTDataLoaderCancellationToken?
}
