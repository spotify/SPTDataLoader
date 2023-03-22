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

import SPTDataLoader

final class StubbedNetwork {
    private(set) lazy var dataLoaderService = makeStubbedService()
    private(set) lazy var dataLoaderFactory = dataLoaderService.createDataLoaderFactory(with: nil)

    func addStub(
        statusCode: Int = 200,
        body: Data? = nil,
        headers: [String: String]? = nil,
        where predicate: @escaping (URLRequest) -> Bool
    ) {
        let stub = Stub(body: body, error: nil, headers: headers, predicate: predicate, statusCode: statusCode)
        StubManager.shared.addStub(stub)
    }

    func addErrorStub(
        domain: String = NSURLErrorDomain,
        code: Int,
        userInfo: [String: Any]? = nil,
        where predicate: @escaping (URLRequest) -> Bool
    ) {
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        let stub = Stub(body: nil, error: error, headers: nil, predicate: predicate, statusCode: 0)
        StubManager.shared.addStub(stub)
    }

    func removeAllStubs() {
        StubManager.shared.removeAllStubs()
    }

    private func makeStubbedService() -> SPTDataLoaderService {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbedProtocol.self]

        return SPTDataLoaderService(configuration: configuration, rateLimiter: nil, resolver: nil)
    }
}

// MARK: -

private final class StubbedProtocol: URLProtocol {
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest, let url = request.url else {
            return false
        }

        return url.scheme == "https" || url.scheme == "http"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let client = client else {
            return
        }

        if let stub = StubManager.shared.stub(for: request) {
            if let error = stub.error {
                client.urlProtocol(self, didFailWithError: error)
            } else {
                if let body = stub.body {
                    client.urlProtocol(self, didLoad: body)
                }

                if
                    let url = request.url,
                    let response = HTTPURLResponse(
                        url: url,
                        statusCode: stub.statusCode,
                        httpVersion: "HTTP/1.1",
                        headerFields: stub.headers
                    )
                {
                    client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
            }
        }

        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Required by abstract superclass -- intentionally empty
    }
}

// MARK: -

private final class StubManager {
    static let shared = StubManager()

    private var stubs: [Stub] = []
    private let workQueue = DispatchQueue(label: "com.spotify.sptdataloaderswift.stubmanager")

    func addStub(_ stub: Stub) {
        workQueue.sync { stubs.append(stub) }
    }

    func removeAllStubs() {
        workQueue.sync { stubs.removeAll() }
    }

    func stub(for request: URLRequest) -> Stub? {
        workQueue.sync { stubs.first(where: { $0.predicate(request) }) }
    }
}

// MARK: -

private struct Stub {
    let body: Data?
    let error: Error?
    let headers: [String: String]?
    let predicate: (URLRequest) -> Bool
    let statusCode: Int
}
