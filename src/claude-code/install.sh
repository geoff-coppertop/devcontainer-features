#!/usr/bin/env bash
set -euo pipefail

CHANNEL="${CHANNEL:-stable}"

if [ "$CHANNEL" != "stable" ] && [ "$CHANNEL" != "latest" ]; then
    echo "Invalid CHANNEL: '$CHANNEL' (expected: stable, latest)" >&2
    exit 1
fi

# Released signing key fingerprint, per
# https://code.claude.com/docs/en/setup#install-with-linux-package-managers
EXPECTED_FP="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gpg

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o /etc/apt/keyrings/claude-code.asc
chmod 0644 /etc/apt/keyrings/claude-code.asc

# Refuse to add the apt source unless the key fingerprint matches what
# Anthropic publishes. Catches MITM / a swapped key on the download host.
ACTUAL_FP=$(gpg --show-keys --with-colons /etc/apt/keyrings/claude-code.asc | awk -F: '/^fpr:/{print $10; exit}')
if [ "$ACTUAL_FP" != "$EXPECTED_FP" ]; then
    echo "Claude Code signing key fingerprint mismatch." >&2
    echo "  expected: $EXPECTED_FP" >&2
    echo "  got:      $ACTUAL_FP" >&2
    exit 1
fi

echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/${CHANNEL} ${CHANNEL} main" \
    > /etc/apt/sources.list.d/claude-code.list
chmod 0644 /etc/apt/sources.list.d/claude-code.list

apt-get update
apt-get install -y --no-install-recommends claude-code
apt-get clean
rm -rf /var/lib/apt/lists/*

# Pre-create the container user's ~/.claude directory with correct ownership.
# Consumers commonly bind a named Docker volume here to persist credentials and
# session memory across rebuilds; when Docker/Podman initialises an empty named
# volume from a mountpoint, it copies the directory's ownership into the
# volume, so this pre-creation step is what lets `claude` write to the volume
# without an EACCES on first run.
_CONTAINER_USER="${_REMOTE_USER:-${USERNAME:-vscode}}"
if id "$_CONTAINER_USER" >/dev/null 2>&1; then
    _CONTAINER_HOME=$(getent passwd "$_CONTAINER_USER" | cut -d: -f6)
    install -d -o "$_CONTAINER_USER" -g "$_CONTAINER_USER" -m 0700 "$_CONTAINER_HOME/.claude"
fi
