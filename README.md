# devcontainer-features

Shared [devcontainer features](https://containers.dev/implementors/features/),
published independently to GHCR, used across this account's devcontainer-based
projects (Connect IQ apps, embedded Rust, Go) so each gets consistent
shell/tooling behavior without duplicating setup per repo.

## Features

| Feature | Purpose |
| --- | --- |
| [`shell-baseline`](src/shell-baseline) | Interactive-shell tooling (fish, starship, zoxide, fzf, eza, bat, lazygit, gitui, delta, fastfetch) plus the shared fish/git config from [dotfiles](https://github.com/geoff-coppertop/dotfiles), installed as plain files. |
| [`connect-iq-sdk`](src/connect-iq-sdk) | JDK + `connect-iq-sdk-manager` CLI, with a specific Garmin Connect IQ SDK version downloaded, license-accepted, and pinned at image build time. |

## Usage

```jsonc
"features": {
    "ghcr.io/geoff-coppertop/devcontainer-features/shell-baseline:1": {},
    "ghcr.io/geoff-coppertop/devcontainer-features/connect-iq-sdk:1": {
        "version": "7.4.0"
    },
    "ghcr.io/devcontainers/features/rust:1": {}
}
```

Compose these alongside official `ghcr.io/devcontainers/features/*` features
for language toolchains.

## Publishing

`.github/workflows/release.yml` runs `devcontainers/action` on every push to
`main` that touches `src/**`, publishing each `src/<name>/` as its own
independently versioned OCI artifact: `ghcr.io/geoff-coppertop/devcontainer-features/<name>:<version>`.

## Testing locally

```bash
devcontainer features test -f shell-baseline -p .
devcontainer features test -f connect-iq-sdk -p .
```
