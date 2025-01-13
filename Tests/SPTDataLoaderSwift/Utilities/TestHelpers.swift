// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import SPTDataLoaderSwift

enum TestError: Error {
    case foo
    case bar
}

struct TestDecodable: Decodable, Equatable {
    let foo: String
}

struct TestSerializer: ResponseSerializer {
    func serialize(response: SPTDataLoaderResponse) throws -> String {
        guard let data = response.body else {
            throw TestError.bar
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw TestError.bar
        }

        return string
    }
}

extension Error {
    var domain: String { (self as NSError).domain }
    var code: Int { (self as NSError).code }
}
