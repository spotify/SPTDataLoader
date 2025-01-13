// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

/// An error that occurs during request execution.
public enum RequestError: Error {
    /// The request could not be initiated.
    case executionFailed
}

/// An error that occurs during response serialization.
public enum ResponseSerializationError: Error {
    /// The data was expected but a null value was provided.
    case dataNotFound
}

/// An error that occurs during response validation.
public enum ResponseValidationError: Error {
    /// The status code was not within the accepted codes.
    case badStatusCode(code: Int)
}
