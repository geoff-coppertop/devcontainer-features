#!/bin/sh
set -e

if [ -z "$VERSION" ]; then
    echo "connect-iq-sdk feature: the 'version' option is required, e.g. { \"version\": \"7.4.0\" }" >&2
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    default-jdk-headless \
    golang-go
apt-get clean
rm -rf /var/lib/apt/lists/*

## Same pin as nixos-config's pkgs/connect-iq-sdk-manager-cli.nix
CONNECT_IQ_SDK_MANAGER_CLI_VERSION="0.8.4"
export GOBIN=/usr/local/bin
go install "github.com/lindell/connect-iq-sdk-manager-cli@v${CONNECT_IQ_SDK_MANAGER_CLI_VERSION}"
mv /usr/local/bin/connect-iq-sdk-manager-cli /usr/local/bin/connect-iq-sdk-manager

_CONTAINER_USER="${_REMOTE_USER:-${USERNAME:-vscode}}"
USER_HOME=$(getent passwd "$_CONTAINER_USER" | cut -d: -f6)

su -s /bin/sh "$_CONTAINER_USER" -c "
    mkdir -p '$USER_HOME/.Garmin/ConnectIQ/Sdks'
    connect-iq-sdk-manager agreement accept
    connect-iq-sdk-manager sdk download '$VERSION'
    connect-iq-sdk-manager sdk set '$VERSION'
"

## Pin the selected SDK's bin/ onto PATH for both bash/sh login shells and fish
SDK_BIN_PATH=$(su -s /bin/sh "$_CONTAINER_USER" -c "connect-iq-sdk-manager sdk current-path --bin" 2>/dev/null || true)
if [ -n "$SDK_BIN_PATH" ]; then
    mkdir -p /etc/fish/conf.d
    echo "fish_add_path --path '$SDK_BIN_PATH'" > /etc/fish/conf.d/connect-iq-sdk.fish
    echo "export PATH=\"$SDK_BIN_PATH:\$PATH\"" > /etc/profile.d/connect-iq-sdk.sh
    chmod 644 /etc/fish/conf.d/connect-iq-sdk.fish /etc/profile.d/connect-iq-sdk.sh
fi
