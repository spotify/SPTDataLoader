#!/usr/bin/env bash

set -euo pipefail

brew update
brew install carthage

carthage build --no-skip-current && carthage archive SPTDataLoader
