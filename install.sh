#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/git/dotfiles}"
BREWFILE="$DOTFILES_DIR/Brewfile"
OS="$(uname -s)"
ARCH="$(uname -m)"

log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[DONE]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[FAIL]\033[0m %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

ensure_brew() {
  if need_cmd brew; then
    ok "Homebrew present: $(brew --version | head -n1)"
    return 0
  fi
  warn "Homebrew not found; installing (NONINTERACTIVE)."
  if [ "$OS" != "Darwin" ]; then
    err "Homebrew install only automated on macOS. Aborting."
    return 1
  fi
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # shellcheck disable=SC1091
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  need_cmd brew || { err "brew failed to install"; return 1; }
  ok "Homebrew installed."
}

brew_bundle() {
  [ -f "$BREWFILE" ] || { warn "No Brewfile at $BREWFILE"; return 0; }
  log "Running brew bundle"
  brew update || true
  brew tap homebrew/bundle || true
  brew bundle --file "$BREWFILE" || true
  ok "brew bundle completed"
}

fzf_setup() {
  if ! need_cmd fzf; then return 0; fi
  local prefix
  prefix="$(brew --prefix fzf 2>/dev/null || true)"
  local installer
  if [ -n "$prefix" ] && [ -x "$prefix/install" ]; then
    log "Configuring fzf key bindings and completion"
    yes | "$prefix/install" --key-bindings --completion --no-bash --no-fish >/dev/null 2>&1 || true
    ok "fzf configured"
  fi
}

link() {
  # link <relative-path-under-repo>
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dst="$HOME/$rel"
  [ -e "$src" ] || { warn "skip link: missing $src"; return 0; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "link exists: ~$rel"
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="$dst.bak-$(date +%Y%m%d-%H%M%S)"
    warn "backing up $dst -> $bak"
    mv "$dst" "$bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "linked ~$rel"
}

clone_repo_if_needed() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    ok "dotfiles repo present"
    return 0
  fi
  log "Cloning public repo flyingrobots/dotfiles"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "https://github.com/flyingrobots/dotfiles.git" "$DOTFILES_DIR"
  ok "cloned dotfiles"
}

main() {
  clone_repo_if_needed
  ensure_brew || true
  brew_bundle || true
  fzf_setup || true
  link ".zshrc"
  # Optional extras: add these to the repo if you want them linked
  [ -f "$DOTFILES_DIR/.fzf-extra.zsh" ] && link ".fzf-extra.zsh"
  [ -f "$DOTFILES_DIR/.cli-goodies.zsh" ] && link ".cli-goodies.zsh"
  ok "Bootstrap complete. Open a new terminal or run: source ~/.zshrc"
}

main "$@"
