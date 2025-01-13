// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Values associated with the response to a `Request`.
public struct Response<Success, Failure: Error> {
    /// The originating request instance.
    public let request: SPTDataLoaderRequest

    /// The underlying response instance.
    public let response: SPTDataLoaderResponse?

    /// The serialized result value.
    public let result: Result<Success, Failure>
}

public extension Response {
    /// The response's content.
    var data: Data? { response?.body }

    /// The serialized success value, otherwise `nil`.
    var value: Success? { result.success }

    /// The serialized error value, otherwise `nil`.
    var error: Failure? { result.failure }
}
