// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

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
    func serialize(response: SPTDataLoaderResponse) throws -> Data {
        guard let data = response.body else {
            throw ResponseSerializationError.dataNotFound
        }

        return data
    }
}

struct DecodableResponseSerializer<Value: Decodable>: ResponseSerializer {
    let decoder: ResponseDecoder

    func serialize(response: SPTDataLoaderResponse) throws -> Value {
        guard let data = response.body else {
            throw ResponseSerializationError.dataNotFound
        }

        return try decoder.decode(Value.self, from: data)
    }
}

struct JSONResponseSerializer: ResponseSerializer {
    let options: JSONSerialization.ReadingOptions

    func serialize(response: SPTDataLoaderResponse) throws -> Any {
        guard let data = response.body else {
            throw ResponseSerializationError.dataNotFound
        }

        return try JSONSerialization.jsonObject(with: data, options: options)
    }
}
