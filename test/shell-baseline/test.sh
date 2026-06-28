#!/bin/bash
set -e
source dev-container-features-test-lib

check "fish installed" bash -c "command -v fish"
check "starship installed" bash -c "command -v starship"
check "zoxide installed" bash -c "command -v zoxide"
check "eza installed" bash -c "command -v eza"
check "bat installed" bash -c "command -v bat"
check "lazygit installed" bash -c "command -v lazygit"
check "gitui installed" bash -c "command -v gitui"
check "delta installed" bash -c "command -v delta"
check "fastfetch installed" bash -c "command -v fastfetch"
check "fish config applied" test -f "$HOME/.config/fish/config.fish"
check "git config applied" test -f "$HOME/.config/git/config"

reportResults
