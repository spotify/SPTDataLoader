// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import Foundation

final class AccessLock {
    private let lock: os_unfair_lock_t

    init() {
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    @discardableResult
    func sync<Result>(closure: () throws -> Result) rethrows -> Result {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }

        return try closure()
    }
}
