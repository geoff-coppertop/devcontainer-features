#!/bin/sh
set -e

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

## eza: official apt repo (no cargo/rust toolchain required)
mkdir -p /etc/apt/keyrings
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt-get update
apt-get install -y eza
apt-get clean
rm -rf /var/lib/apt/lists/*

## starship, zoxide: official install scripts (static binaries)
curl -sS https://starship.rs/install.sh | sh -s -- -y
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

## lazygit (Go binary release)
LAZYGIT_VERSION=$(curl -sf https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name' | sed 's/^v//')
curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
rm /tmp/lazygit.tar.gz

## gitui (prebuilt release binary)
GITUI_VERSION=$(curl -sf https://api.github.com/repos/extrawurst/gitui/releases/latest | jq -r '.tag_name')
curl -sLo /tmp/gitui.tar.gz "https://github.com/extrawurst/gitui/releases/download/${GITUI_VERSION}/gitui-linux-x86_64.tar.gz"
tar -xzf /tmp/gitui.tar.gz -C /usr/local/bin gitui
rm /tmp/gitui.tar.gz

## git-delta
DELTA_VERSION=$(curl -sf https://api.github.com/repos/dandavison/delta/releases/latest | jq -r '.tag_name')
curl -sLo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
dpkg -i /tmp/delta.deb
rm /tmp/delta.deb

## fastfetch (not in Debian bookworm standard repos)
FASTFETCH_VERSION=$(curl -sf https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r '.tag_name')
curl -sLo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
dpkg -i /tmp/fastfetch.deb
rm /tmp/fastfetch.deb

_CONTAINER_USER="${_REMOTE_USER:-${USERNAME:-vscode}}"

## Set fish as the container user's default shell
if id "$_CONTAINER_USER" >/dev/null 2>&1; then
    usermod -s /usr/bin/fish "$_CONTAINER_USER"
fi

## Apply shared dotfiles (fish config, git aliases/commit template) from geoff-coppertop/dotfiles
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
