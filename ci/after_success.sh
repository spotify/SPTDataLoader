#!/usr/bin/env bash

set -euo pipefail

bundle exec slather coverage \
    --input-format profdata \
    --cobertura-xml \
    --ignore "../**/*/Xcode*" \
    --output-directory slather-report \
    --scheme SPTDataLoader \
    SPTDataLoader.xcodeproj

bundle exec slather
