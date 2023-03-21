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
