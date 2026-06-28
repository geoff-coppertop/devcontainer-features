#!/bin/bash
set -e
source dev-container-features-test-lib

check "claude binary on PATH" bash -c "command -v claude"
check "claude --version succeeds" bash -c "claude --version"
check "apt source configured" test -f /etc/apt/sources.list.d/claude-code.list
check "signing key installed" test -f /etc/apt/keyrings/claude-code.asc

reportResults
