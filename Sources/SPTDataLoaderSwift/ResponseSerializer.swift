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

/// A protocol that provides response type serialization.
public protocol ResponseSerializer {
    /// The serialized instance type to be returned.
    associatedtype Output

    /// Serializes a response into the associated type.
    /// - Parameter response: The `SPTDataLoaderResponse` received for a request.
    /// - Throws: An `Error` resulting from failed serialization.
    /// - Returns: A serialized instance of the associated type.
    func serialize(response: SPTDataLoaderResponse) throws -> Output
}

struct DataResponseSerializer: ResponseSerializer {
    func serialize(response: SPTDataLoaderResponse) throws -> Data? {
        if let error = response.error {
            throw error
        }

        return response.body
    }
}

struct DecodableResponseSerializer<Value: Decodable>: ResponseSerializer {
    let decoder: ResponseDecoder

    func serialize(response: SPTDataLoaderResponse) throws -> Value {
        if let error = response.error {
            throw error
        }

        return try decoder.decode(Value.self, from: response.body ?? Data())
    }
}

struct JSONResponseSerializer: ResponseSerializer {
    let options: JSONSerialization.ReadingOptions

    func serialize(response: SPTDataLoaderResponse) throws -> Any {
        if let error = response.error {
            throw error
        }

        return try JSONSerialization.jsonObject(with: response.body ?? Data(), options: options)
    }
}
