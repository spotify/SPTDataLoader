#!/usr/bin/env bash

source "./ci/lib/travis_helpers.sh"

set -euo pipefail

travis_fold_open "Install Carthage"
brew update
brew install carthage
travis_fold_close "Install Carthage"

travis_fold_open "Archive"
carthage build --no-skip-current && carthage archive SPTDataLoader
travis_fold_close "Archive"
