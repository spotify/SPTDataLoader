// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A protocol that provides response value decoding.
public protocol ResponseDecoder {
    /// Decodes an instance of the indicated type.
    /// - Parameter type: The type of the value to decode.
    /// - Parameter data: The data to decode from.
    /// - Returns: A value of the requested type.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: ResponseDecoder {}
extension PropertyListDecoder: ResponseDecoder {}
