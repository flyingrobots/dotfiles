#!/usr/bin/env bash
# dotfiles bootstrap and symlink installer
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m ✔︎\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m ⚠\033[0m %s\n" "$*"; }

link_file() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        local current
        current="$(readlink "$dst")"
        if [ "$current" = "$src" ]; then
            ok "Already linked: $dst -> $src"
            return
        fi
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        warn "Backing up existing $dst to $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi

    ln -s "$src" "$dst"
    ok "Linked: $dst -> $src"
}

info "Installing dotfiles from $DOTFILES_DIR to $HOME"

# Shell configs
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"

# Git & Tmux
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# .config applications
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.config/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$DOTFILES_DIR/.config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# .local/bin tools
mkdir -p "$HOME/.local/bin"
for tool in "$DOTFILES_DIR/.local/bin/"*; do
    if [ -f "$tool" ]; then
        base="$(basename "$tool")"
        chmod +x "$tool"
        link_file "$tool" "$HOME/.local/bin/$base"
    fi
done

# LaunchAgents (optional auto-boot services)
if [ -d "$DOTFILES_DIR/launchd" ]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    for plist in "$DOTFILES_DIR/launchd/"*.plist; do
        if [ -f "$plist" ]; then
            base="$(basename "$plist")"
            link_file "$plist" "$HOME/Library/LaunchAgents/$base"
        fi
    done
fi

info "Dotfiles installation complete!"
