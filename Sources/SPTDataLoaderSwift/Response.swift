// Copyright 2015-2023 Spotify AB
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
