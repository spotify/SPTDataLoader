#!/usr/bin/env bash

source "./ci/lib/travis_helpers.sh"

set -euo pipefail

# License conformance
travis_fold_open "License conformance"
./ci/validate_license_conformance.sh {include/SPTDataLoader/*.h,SPTDataLoader/*.{h,m}}
travis_fold_close "License conformance"


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


# Linting
travis_fold_open "Linting"
echo "Linting CocoaPods specification"
pod spec lint SPTDataLoader.podspec --quick
travis_fold_close "Linting"
