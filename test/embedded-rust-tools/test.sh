#!/bin/bash
set -e
source dev-container-features-test-lib

check "cargo on PATH"          bash -c "command -v cargo"
check "cargo-binstall installed" bash -c "command -v cargo-binstall"
check "cargo-generate installed" bash -c "command -v cargo-generate"
check "flip-link installed"      bash -c "command -v flip-link"
check "probe-rs installed"       bash -c "command -v probe-rs"

reportResults
