#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/git/dotfiles}"
BREWFILE="$DOTFILES_DIR/Brewfile"
log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }

if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found" >&2
  exit 1
fi
log "Dumping current Homebrew snapshot to $BREWFILE"
brew bundle dump --file "$BREWFILE" --force --describe
if command -v git >/dev/null 2>&1 && [ -d "$DOTFILES_DIR/.git" ]; then
  cd "$DOTFILES_DIR"
  git add Brewfile
  git commit -m "chore(brew): update Brewfile snapshot" || true
  log "Committed updated Brewfile. Push with: git push"
fi
