#!/usr/bin/env bash

set -euo pipefail

xcrun xcodebuild $BUILD_ACTIONS \
	NSUnbufferedIO=YES \
    -project SPTDataLoader.xcodeproj \
    -scheme "$SCHEME" \
    -sdk "$TEST_SDK" \
    -destination "$TEST_DEST" \
    $EXTRA_ARGUMENTS \
         | xcpretty -c -f `xcpretty-travis-formatter`

pod spec lint SPTDataLoader.podspec --quick
