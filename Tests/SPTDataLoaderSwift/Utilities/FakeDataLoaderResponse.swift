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

import SPTDataLoader

final class FakeDataLoaderResponse: SPTDataLoaderResponse {
    private let _request: SPTDataLoaderRequest
    private let _body: Data?
    private let _error: Error?
    private let _headers: [String: String]
    private let _statusCode: Int

    init(
        request: SPTDataLoaderRequest,
        body: Data? = nil,
        error: Error? = nil,
        headers: [String: String] = [:],
        statusCode: Int = 200
    ) {
        _request = request
        _body = body
        _error = error
        _headers = headers
        _statusCode = statusCode
        super.init()
    }

    override var body: Data? { _body }
    override var error: Error? { _error }
    override var request: SPTDataLoaderRequest { _request }
    override var responseHeaders: [String : String] { _headers }
    override var statusCode: SPTDataLoaderResponseHTTPStatusCode {
        SPTDataLoaderResponseHTTPStatusCode(rawValue: _statusCode) ?? .invalid
    }
}
