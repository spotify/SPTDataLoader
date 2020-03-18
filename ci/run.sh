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
  LOG="$1"
  heading "$LOG"
  shift
  export NSUnbufferedIO=YES
  set -o pipefail && xcodebuild \
    -workspace SPTDataLoader.xcworkspace \
    -UseSanitizedBuildSystemEnvironment=YES \
    -derivedDataPath build/DerivedData \
    CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
    "$@" | xcpretty || fail "$LOG failed"
}

if [[ -n "$GITHUB_WORKFLOW" ]]; then
  heading "Installing Tools"
  gem install xcpretty cocoapods
  export IS_CI=1
fi

heading "Linting Podspec"
pod spec lint SPTDataLoader.podspec --quick || \
  fail "Podspec lint failed"

heading "Validating License Conformance"
git ls-files | egrep "\\.(h|m|mm)$" | \
  xargs ci/validate_license_conformance.sh ci/expected_license_header.txt || \
  fail "License Validation Failed"

#
# BUILD LIBRARIES
#

build_library() {
  xcb "Build Library [$1]" \
    build -scheme SPTDataLoader \
    -sdk "$1" \
    -configuration Release
}

build_library iphoneos
build_library iphonesimulator
build_library macosx
build_library watchos
build_library watchsimulator
build_library appletvos
build_library appletvsimulator

#
# BUILD FRAMEWORKS
#

build_framework() {
  xcb "Build Framework [$1] [$2]" \
    build -scheme "$1" \
    -sdk "$2" \
    -configuration Release
}

build_framework SPTDataLoader-iOS iphoneos
build_framework SPTDataLoader-iOS iphonesimulator
build_framework SPTDataLoader-OSX macosx
build_framework SPTDataLoader-Watch watchos
build_framework SPTDataLoader-Watch watchsimulator
build_framework SPTDataLoader-TV appletvos
build_framework SPTDataLoader-TV appletvsimulator

#
# BUILD DEMO APP
#

xcb "Build Demo App for Simulator" \
  build -scheme "SPTDataLoaderDemo" \
  -sdk iphonesimulator \
  -configuration Release

#
# RUN TESTS
#

xcb "Run tests for macOS" test \
  -scheme "SPTDataLoader" \
  -enableCodeCoverage YES \
  -sdk macosx

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

xcb "Run tests for iOS" test \
  -scheme "SPTDataLoader" \
  -enableCodeCoverage YES \
  -destination "platform=iOS Simulator,name=dataloader-tester-ios"

create_sim dataloader-tester-tvos tvOS com.apple.CoreSimulator.SimDeviceType.Apple-TV-1080p

xcb "Run tests for tvOS" test \
  -scheme "SPTDataLoader" \
  -enableCodeCoverage YES \
  -destination "platform=tvOS Simulator,name=dataloader-tester-tvos"

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
build/codecov.sh -D build/DerivedData -X xcodellvm $CODECOV_EXTRA
