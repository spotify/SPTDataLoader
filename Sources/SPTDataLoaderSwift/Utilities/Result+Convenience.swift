// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

extension Result {
    var success: Success? {
        guard case .success(let value) = self else {
            return nil
        }

        return value
    }

    var failure: Failure? {
        guard case .failure(let error) = self else {
            return nil
        }

        return error
    }
}
