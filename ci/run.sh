#!/bin/bash

heading() {
  echo ""
  echo -e "\033[0;35m** ${*} **\033[0m"
  echo ""
}

fail() {
  >&2 echo "error: $@"
  exit 1
}

xcb() {
  local log="$1"
  heading "$log"
  shift
  export NSUnbufferedIO=YES
  set -o pipefail && xcodebuild \
    -workspace SPTDataLoader.xcworkspace \
    -UseSanitizedBuildSystemEnvironment=YES \
    CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
    "$@" | xcpretty || fail "$log failed"
}

DERIVED_DATA_COMMON="build/DD/common"
DERIVED_DATA_TEST="build/DD/test"

if [[ -n "$GITHUB_WORKFLOW" ]]; then
  heading "Installing Tools"
  gem install xcpretty cocoapods
  export IS_CI=1
fi

heading "Linting Podspec"
pod spec lint SPTDataLoader.podspec --quick || \
  fail "Podspec lint failed"

heading "Validating License Conformance"
git ls-files | egrep "\\.(h|m|mm|swift)$" | \
  xargs ci/validate_license_conformance.sh ci/expected_license_header.txt || \
  fail "License Validation Failed"

#
# BUILD LIBRARIES
#

build_library() {
  xcb "Build Library [$1] [$2]" build \
    -scheme "$1" \
    -sdk "$2" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_COMMON"
}

build_library SPTDataLoader iphoneos
build_library SPTDataLoader iphonesimulator
build_library SPTDataLoader macosx
build_library SPTDataLoader watchos
build_library SPTDataLoader watchsimulator
build_library SPTDataLoader appletvos
build_library SPTDataLoader appletvsimulator

build_library SPTDataLoaderSwift iphoneos
build_library SPTDataLoaderSwift iphonesimulator
build_library SPTDataLoaderSwift macosx
build_library SPTDataLoaderSwift watchos
build_library SPTDataLoaderSwift watchsimulator
build_library SPTDataLoaderSwift appletvos
build_library SPTDataLoaderSwift appletvsimulator

#
# BUILD FRAMEWORKS
#

build_framework() {
  xcb "Build Framework [$1] [$2]" build \
    -scheme "$1" \
    -sdk "$2" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_COMMON"
}

build_framework SPTDataLoader-iOS iphoneos
build_framework SPTDataLoader-iOS iphonesimulator
build_framework SPTDataLoader-OSX macosx
build_framework SPTDataLoader-Watch watchos
build_framework SPTDataLoader-Watch watchsimulator
build_framework SPTDataLoader-TV appletvos
build_framework SPTDataLoader-TV appletvsimulator

build_framework SPTDataLoaderSwift-iOS iphoneos
build_framework SPTDataLoaderSwift-iOS iphonesimulator
build_framework SPTDataLoaderSwift-OSX macosx
build_framework SPTDataLoaderSwift-Watch watchos
build_framework SPTDataLoaderSwift-Watch watchsimulator
build_framework SPTDataLoaderSwift-TV appletvos
build_framework SPTDataLoaderSwift-TV appletvsimulator

#
# BUILD DEMO APP
#

xcb "Build Demo App for Simulator" build \
  -scheme "SPTDataLoaderDemo" \
  -sdk iphonesimulator \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_COMMON"

#
# RUN TESTS
#

xcb "Run tests for macOS" test \
  -scheme "ALL_TESTS" \
  -enableCodeCoverage YES \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA_TEST/macos"

create_sim() {
  if sh -c "xcrun simctl list devices | grep -q $1" ; then
    echo "Delete existing simulator: $1"
    xcrun simctl delete "$1"
  fi

  echo "Create simulator: $1"
  local runtime=`xcrun simctl list runtimes | grep "$2" | awk '{print $NF}' | tail -n 1`
  xcrun simctl create "$1" "$3" "$runtime" || fail "Failed to create $2 simulator for testing"
}

create_sim dataloader-tester-ios iOS com.apple.CoreSimulator.SimDeviceType.iPhone-8
create_sim dataloaderswift-tester-ios iOS com.apple.CoreSimulator.SimDeviceType.iPhone-8

xcb "Run tests for iOS" test \
  -scheme "ALL_TESTS" \
  -enableCodeCoverage YES \
  -destination "platform=iOS Simulator,name=dataloader-tester-ios" \
  -derivedDataPath "$DERIVED_DATA_TEST/ios"

create_sim dataloader-tester-tvos tvOS com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p
create_sim dataloaderswift-tester-tvos tvOS com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p

xcb "Run tests for tvOS" test \
  -scheme "ALL_TESTS" \
  -enableCodeCoverage YES \
  -destination "platform=tvOS Simulator,name=dataloader-tester-tvos" \
  -derivedDataPath "$DERIVED_DATA_TEST/tvos"

#
# CODECOV
#

# output a bunch of stuff that codecov might recognize
if [[ -n "$GITHUB_WORKFLOW" ]]; then
  PR_CANDIDATE=`echo "$GITHUB_REF" | egrep -o "pull/\d+" | egrep -o "\d+"`
  [[ -n "$PR_CANDIDATE" ]] && export VCS_PULL_REQUEST="$PR_CANDIDATE"
  export CI_BUILD_ID="$RUNNER_TRACKING_ID"
  export CI_JOB_ID="$RUNNER_TRACKING_ID"
  export CODECOV_SLUG="$GITHUB_REPOSITORY"
  export GIT_BRANCH="$GITHUB_REF"
  export GIT_COMMIT="$GITHUB_SHA"
  export VCS_BRANCH_NAME="$GITHUB_REF"
  export VCS_COMMIT_ID="$GITHUB_SHA"
  export VCS_SLUG="$GITHUB_REPOSITORY"
fi

curl -sfL https://codecov.io/bash > build/codecov.sh
chmod +x build/codecov.sh
[[ "$IS_CI" == "1" ]] || CODECOV_EXTRA="-d"

coverage_report() {
  # clean up previous coverage files so they don't leak into one another
  rm -f *.coverage.txt
  build/codecov.sh -n "$1" -D "$DERIVED_DATA_TEST/$1" -X xcodellvm $CODECOV_EXTRA
}

coverage_report macos
coverage_report tvos
coverage_report ios
