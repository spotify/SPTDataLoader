// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import SPTDataLoader

final class DataLoaderResponseFake: SPTDataLoaderResponse {
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
