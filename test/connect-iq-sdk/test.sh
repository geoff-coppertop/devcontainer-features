#!/bin/bash
set -e
source dev-container-features-test-lib

check "java installed" bash -c "command -v java"
check "connect-iq-sdk-manager installed" bash -c "command -v connect-iq-sdk-manager"

reportResults
