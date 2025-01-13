// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import Foundation

final class DataLoaderWrapper: NSObject {
    private let dataLoader: SPTDataLoader

    private let accessLock = AccessLock()
    private var requests: [Int64: Request] = [:]

    init(dataLoader: SPTDataLoader) {
        self.dataLoader = dataLoader
    }
}

// MARK: - DataLoader

extension DataLoaderWrapper: DataLoader {
    var activeRequests: [Request] { accessLock.sync { Array(requests.values) } }

    func request(_ url: URL, sourceIdentifier: String?) -> Request {
        let sptRequest = SPTDataLoaderRequest(url: url, sourceIdentifier: sourceIdentifier)
        let request = Request(request: sptRequest) { [weak self] request in
            guard let self = self else {
                return nil
            }

            self.accessLock.sync {
                self.requests[sptRequest.uniqueIdentifier] = request
            }

            return self.dataLoader.perform(sptRequest)
        }

        return request
    }

    func cancelActiveRequests() {
        var activeRequests: [Request] = []

        accessLock.sync {
            activeRequests.append(contentsOf: requests.values)
            requests.removeAll()
        }

        activeRequests.forEach { request in request.cancel() }
    }
}

// MARK: - SPTDataLoaderDelegate

extension DataLoaderWrapper: SPTDataLoaderDelegate {
    func dataLoader(_ dataLoader: SPTDataLoader, didReceiveSuccessfulResponse response: SPTDataLoaderResponse) {
        handleResponse(response)
    }

    func dataLoader(_ dataLoader: SPTDataLoader, didReceiveErrorResponse response: SPTDataLoaderResponse) {
        handleResponse(response)
    }

    func dataLoader(_ dataLoader: SPTDataLoader, didCancel request: SPTDataLoaderRequest) {
        accessLock.sync {
            requests[request.uniqueIdentifier] = nil
        }
    }

    private func handleResponse(_ response: SPTDataLoaderResponse) {
        var request: Request?

        accessLock.sync {
            request = requests.removeValue(forKey: response.request.uniqueIdentifier)
        }

        request.map { request in request.processResponse(response) }
    }
}
