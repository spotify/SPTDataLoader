#!/usr/bin/env bash

set -euo pipefail

xcrun xcodebuild build test \
	NSUnbufferedIO=YES \
    -project SPTDataLoader.xcodeproj \
    -scheme "$SCHEME" \
    -sdk "$TEST_SDK" \
    -destination "$TEST_DEST" \
    -enableCodeCoverage YES \
         | xcpretty -c -f `xcpretty-travis-formatter`

pod spec lint SPTDataLoader.podspec --quick
