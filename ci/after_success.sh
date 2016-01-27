#!/usr/bin/env bash

source "./ci/lib/travis_helpers.sh"

set -euo pipefail

travis_fold_open "Slather"
bundle exec slather coverage \
    --input-format profdata \
    --scheme SPTDataLoader \
    SPTDataLoader.xcodeproj
travis_fold_close "Slather"
