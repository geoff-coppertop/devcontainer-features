#!/usr/bin/env bash
set -euo pipefail

# --- Versions ----------------------------------------------------------------
# Pinned defaults. Override per build by setting the matching option in
# devcontainer.json (e.g. "lazygitVersion": "0.62.2"). Pass "latest" to resolve
# the newest tag via the GitHub API; this is rate-limited (60/hr anonymous) and
# not recommended for unattended CI builds.
LAZYGIT_VERSION="${LAZYGITVERSION:-0.62.2}"
GITUI_VERSION="${GITUIVERSION:-0.28.1}"
DELTA_VERSION="${DELTAVERSION:-0.19.2}"
FASTFETCH_VERSION="${FASTFETCHVERSION:-2.65.1}"

# Resolve "latest" -> concrete tag. curl -f makes API errors (rate limit, etc.)
# fail loudly instead of silently producing an invalid version string.
resolve_latest() {
    local repo="$1" strip_v="${2:-0}" tag
    tag=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | jq -er '.tag_name')
    if [ "$strip_v" = "1" ]; then printf '%s\n' "${tag#v}"; else printf '%s\n' "$tag"; fi
}

[ "$LAZYGIT_VERSION"   = "latest" ] && LAZYGIT_VERSION=$(resolve_latest jesseduffield/lazygit 1)
[ "$GITUI_VERSION"     = "latest" ] && GITUI_VERSION=$(resolve_latest extrawurst/gitui 1)
[ "$DELTA_VERSION"     = "latest" ] && DELTA_VERSION=$(resolve_latest dandavison/delta 0)
[ "$FASTFETCH_VERSION" = "latest" ] && FASTFETCH_VERSION=$(resolve_latest fastfetch-cli/fastfetch 0)

# --- apt baseline ------------------------------------------------------------
apt-get update
apt-get install -y --no-install-recommends \
    bat \
    btop \
    ca-certificates \
    curl \
    duf \
    fd-find \
    fish \
    fzf \
    git \
    gpg \
    jq \
    ripgrep \
    tree \
    unzip \
    vim \
    zip
apt-get clean
rm -rf /var/lib/apt/lists/*

## Debian ships these tools under different binary names
ln -sf /usr/bin/batcat /usr/local/bin/bat
ln -sf /usr/bin/fdfind /usr/local/bin/fd

# --- eza (third-party apt repo) ----------------------------------------------
mkdir -p /etc/apt/keyrings
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt-get update
apt-get install -y eza
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- starship, zoxide (upstream install scripts) -----------------------------
# zoxide's installer defaults to $HOME/.local/bin; the feature install runs as
# root with HOME pointing at the container user's home, which lands the binary
# in a directory the user's PATH doesn't include. Pin both to system paths.
curl -fsSL https://starship.rs/install.sh | sh -s -- -y
curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir=/usr/local/bin --man-dir=/usr/local/share/man

# --- lazygit -----------------------------------------------------------------
curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
rm /tmp/lazygit.tar.gz

# --- gitui -------------------------------------------------------------------
# Archive contains only ./gitui; extract whole archive into /usr/local/bin.
curl -fsSLo /tmp/gitui.tar.gz "https://github.com/extrawurst/gitui/releases/download/v${GITUI_VERSION}/gitui-linux-x86_64.tar.gz"
tar -xzf /tmp/gitui.tar.gz -C /usr/local/bin
rm /tmp/gitui.tar.gz

# --- git-delta ---------------------------------------------------------------
curl -fsSLo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
dpkg -i /tmp/delta.deb
rm /tmp/delta.deb

# --- fastfetch ---------------------------------------------------------------
curl -fsSLo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
dpkg -i /tmp/fastfetch.deb
rm /tmp/fastfetch.deb

# --- shell + dotfiles --------------------------------------------------------
_CONTAINER_USER="${_REMOTE_USER:-${USERNAME:-vscode}}"

if id "$_CONTAINER_USER" >/dev/null 2>&1; then
    usermod -s /usr/bin/fish "$_CONTAINER_USER"
fi

DOTFILES_REF="${DOTFILESREF:-75100ca540a531938db147aa5abcc1059189272e}"
DOTFILES_DIR=$(mktemp -d)
git clone --quiet https://github.com/geoff-coppertop/dotfiles.git "$DOTFILES_DIR"
git -C "$DOTFILES_DIR" checkout --quiet "$DOTFILES_REF"

_CONTAINER_HOME=$(getent passwd "$_CONTAINER_USER" | cut -d: -f6)
install -d -o "$_CONTAINER_USER" -m755 "$_CONTAINER_HOME/.config/fish" "$_CONTAINER_HOME/.config/git"
install -o "$_CONTAINER_USER" -m644 "$DOTFILES_DIR/fish/config.fish" "$_CONTAINER_HOME/.config/fish/config.fish"
install -o "$_CONTAINER_USER" -m644 "$DOTFILES_DIR/git/config" "$_CONTAINER_HOME/.config/git/config"
install -o "$_CONTAINER_USER" -m644 "$DOTFILES_DIR/git/commit-template" "$_CONTAINER_HOME/.config/git/commit-template"
rm -rf "$DOTFILES_DIR"
