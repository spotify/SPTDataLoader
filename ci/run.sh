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
    "$@" | xcbeautify || fail "$log failed"
}

build_target() {
  xcb "Build Target [$1] [$2]" build \
    -scheme "$1" \
    -destination "$2" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_COMMON"
}

DERIVED_DATA_COMMON="build/DerivedData/common"
DERIVED_DATA_TEST="build/DerivedData/test"

if [[ -n "$GITHUB_WORKFLOW" ]]; then
  heading "Installing Tools"
  gem install cocoapods
  brew install xcbeautify
  export IS_CI=1
fi

heading "Linting Podspec"
pod spec lint SPTDataLoader.podspec --quick || \
  fail "Podspec lint failed"

heading "Validating License Conformance"
git ls-files | egrep "\\.(h|m|mm)$" | \
  xargs ci/validate_license_conformance.sh ci/expected_license_header.txt || \
  fail "License Validation Failed"

heading "Validating Swift License Conformance"
git ls-files | egrep "\\.swift$" | \
  xargs ci/validate_license_conformance.sh ci/expected_license_header_swift.txt || \
  fail "Swift License Validation Failed"

#
# BUILD LIBRARIES
#

build_target SPTDataLoader "generic/platform=iOS"
build_target SPTDataLoader "generic/platform=iOS Simulator"
build_target SPTDataLoader "generic/platform=macOS"
build_target SPTDataLoader "generic/platform=watchOS"
build_target SPTDataLoader "generic/platform=watchOS Simulator"
build_target SPTDataLoader "generic/platform=tvOS"
build_target SPTDataLoader "generic/platform=tvOS Simulator"

build_target SPTDataLoaderSwift "generic/platform=iOS"
build_target SPTDataLoaderSwift "generic/platform=iOS Simulator"
build_target SPTDataLoaderSwift "generic/platform=macOS"
build_target SPTDataLoaderSwift "generic/platform=watchOS"
build_target SPTDataLoaderSwift "generic/platform=watchOS Simulator"
build_target SPTDataLoaderSwift "generic/platform=tvOS"
build_target SPTDataLoaderSwift "generic/platform=tvOS Simulator"

#
# BUILD FRAMEWORKS
#

build_target SPTDataLoader-iOS "generic/platform=iOS"
build_target SPTDataLoader-iOS "generic/platform=iOS Simulator"
build_target SPTDataLoader-OSX "generic/platform=macOS"
build_target SPTDataLoader-Watch "generic/platform=watchOS"
build_target SPTDataLoader-Watch "generic/platform=watchOS Simulator"
build_target SPTDataLoader-TV "generic/platform=tvOS"
build_target SPTDataLoader-TV "generic/platform=tvOS Simulator"

build_target SPTDataLoaderSwift-iOS "generic/platform=iOS"
build_target SPTDataLoaderSwift-iOS "generic/platform=iOS Simulator"
build_target SPTDataLoaderSwift-OSX "generic/platform=macOS"
build_target SPTDataLoaderSwift-Watch "generic/platform=watchOS"
build_target SPTDataLoaderSwift-Watch "generic/platform=watchOS Simulator"
build_target SPTDataLoaderSwift-TV "generic/platform=tvOS"
build_target SPTDataLoaderSwift-TV "generic/platform=tvOS Simulator"

#
# BUILD DEMO APP
#

xcb "Build Demo App for Simulator" build \
  -scheme "SPTDataLoaderDemo" \
  -destination "generic/platform=iOS Simulator" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_COMMON"

#
# RUN TESTS
#

xcb "Run tests for macOS" test \
  -scheme "ALL_TESTS" \
  -enableCodeCoverage YES \
  -destination "platform=macOS" \
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

create_sim dataloader-tester-ios iOS com.apple.CoreSimulator.SimDeviceType.iPhone-XR

xcb "Run tests for iOS" test \
  -scheme "ALL_TESTS" \
  -enableCodeCoverage YES \
  -destination "platform=iOS Simulator,name=dataloader-tester-ios" \
  -derivedDataPath "$DERIVED_DATA_TEST/ios"

create_sim dataloader-tester-tvos tvOS com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p

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
  build/codecov.sh -F "$1" -D "$DERIVED_DATA_TEST/$1" -X xcodellvm $CODECOV_EXTRA
  if [[ "$IS_CI" == "1" ]]; then
    # clean up coverage files so they don't leak into the next processing run
    rm -f *.coverage.txt
  elif compgen -G "*.coverage.txt" > /dev/null; then
    # move when running locally so they don't get overwritten
    mkdir -p "build/coverage/$1"
    mv *.coverage.txt "build/coverage/$1"
  fi
}

coverage_report macos
coverage_report tvos
coverage_report ios
