#!/usr/bin/env bash
set -euo pipefail

# The official rust feature sets CARGO_HOME/RUSTUP_HOME via containerEnv,
# which only applies at runtime. At feature-install time those env vars
# aren't propagated, so resolve them explicitly.
export CARGO_HOME="${CARGO_HOME:-/usr/local/cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-/usr/local/rustup}"
export PATH="${CARGO_HOME}/bin:${PATH}"

if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo not found on PATH. Install ghcr.io/devcontainers/features/rust before this feature." >&2
    exit 1
fi

# cargo-binstall queries api.github.com to discover release assets; anonymous
# calls are limited to 60/hr per IP. Surface a user-supplied token if one was
# passed as a feature option.
if [ -n "${GITHUBTOKEN:-}" ]; then
    export GITHUB_TOKEN="${GITHUBTOKEN}"
fi

# Install cargo-binstall from its own prebuilt release rather than compiling
# from source. The published script honours CARGO_HOME so the binary lands
# in /usr/local/cargo/bin alongside cargo.
curl -fsSL --proto '=https' --tlsv1.2 \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
    | bash

# Everything else has prebuilt artefacts cargo-binstall can fetch.
# --no-confirm: don't prompt during the unattended feature install.
cargo binstall --no-confirm cargo-generate flip-link probe-rs-tools
