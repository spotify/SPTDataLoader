#!/usr/bin/env bash

set -euo pipefail

carthage build --no-skip-current && carthage archive SPTDataLoader
