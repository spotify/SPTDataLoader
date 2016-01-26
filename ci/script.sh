#!/usr/bin/env bash


set -euo pipefail

# Executing build actions
echo "Executing the build actions: $BUILD_ACTIONS"
xcrun xcodebuild $BUILD_ACTIONS \
    NSUnbufferedIO=YES \
    -project SPTDataLoader.xcodeproj \
    -scheme "$SCHEME" \
    -sdk "$TEST_SDK" \
    -destination "$TEST_DEST" \
    $EXTRA_ARGUMENTS \
        | xcpretty -c -f `xcpretty-travis-formatter`


# License conformance
./ci/validate_license_conformance.sh {include/SPTDataLoader/*.h,SPTDataLoader/*.{h,m}}


# Lint our CocoaPods specification.
pod spec lint SPTDataLoader.podspec --quick
