// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

@testable import SPTDataLoaderSwift

import Foundation
import XCTest

class SPTDataLoaderFactoryConvenienceTest: XCTestCase {
    func test_factory_shouldMakeDataLoader_whenRequested() {
        // Given
        let factory = SPTDataLoaderFactory()

        // When
        let dataLoader = factory.makeDataLoader()

        // Then
        XCTAssertTrue(dataLoader is DataLoaderWrapper)
    }
}
