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
