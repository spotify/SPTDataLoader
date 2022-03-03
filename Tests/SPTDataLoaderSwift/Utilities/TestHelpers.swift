// Copyright 2015-2022 Spotify AB
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
