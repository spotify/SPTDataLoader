// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import SPTDataLoader

final class CancellationTokenFake: NSObject, SPTDataLoaderCancellationToken {
    var isCancelled: Bool = false
    var objectToCancel: Any?

    weak var delegate: SPTDataLoaderCancellationTokenDelegate?

    func cancel() {
        isCancelled = true
    }
}
