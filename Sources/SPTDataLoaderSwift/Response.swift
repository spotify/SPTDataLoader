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

/// Values associated with the response to a `SPTDataLoaderRequest`.
public struct Response<Success, Failure: Error> {
    /// The underlying response object.
    public let response: SPTDataLoaderResponse

    /// The serialized result value.
    public let result: Result<Success, Failure>

    /// The originating request object.
    public var request: SPTDataLoaderRequest { response.request }

    /// The response's content.
    public var data: Data? { response.body }

    /// The serialized success value, otherwise `nil`.
    public var value: Success? {
        guard case .success(let value) = result else {
            return nil
        }

        return value
    }

    /// The serialized error value, otherwise `nil`.
    public var error: Failure? {
        guard case .failure(let error) = result else {
            return nil
        }

        return error
    }
}
