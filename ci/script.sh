#!/usr/bin/env bash

set -euo pipefail

xcrun xcodebuild build test \
	NSUnbufferedIO=YES \
    -project SPTDataLoader.xcodeproj \
    -scheme SPTDataLoader \
    -sdk $TEST_SDK \
    -destination "platform=iOS Simulator,OS=$OS,name=$NAME" \
    -enableCodeCoverage YES \
         | xcpretty -c -f `xcpretty-travis-formatter`

pod spec lint SPTDataLoader.podspec
