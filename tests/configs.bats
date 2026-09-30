#!/usr/bin/env bats

setup() {
  DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
}

@test "configs: zsh configuration syntax is valid" {
  run zsh -n "$DOTFILES_DIR/.zshrc"
  [ "$status" -eq 0 ]

  run zsh -n "$DOTFILES_DIR/.zshenv"
  [ "$status" -eq 0 ]

  run zsh -n "$DOTFILES_DIR/.zprofile"
  [ "$status" -eq 0 ]
}

@test "configs: ghostty config specifies Monaspace Radon NF and ligatures" {
  run grep 'font-family = "Monaspace Radon NF"' "$DOTFILES_DIR/.config/ghostty/config"
  [ "$status" -eq 0 ]

  run grep 'font-feature = calt' "$DOTFILES_DIR/.config/ghostty/config"
  [ "$status" -eq 0 ]

  run grep 'macos-titlebar-style = tabs' "$DOTFILES_DIR/.config/ghostty/config"
  [ "$status" -eq 0 ]
}

@test "configs: git config uses delta pager and ssh signing" {
  run git config -f "$DOTFILES_DIR/.gitconfig" --get core.pager
  [ "$status" -eq 0 ]
  [ "$output" = "delta" ]

  run git config -f "$DOTFILES_DIR/.gitconfig" --get gpg.format
  [ "$status" -eq 0 ]
  [ "$output" = "ssh" ]
}

@test "configs: ask CLI displays usage without crashing" {
  run "$DOTFILES_DIR/.local/bin/ask"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage: ask" ]]
}

@test "configs: tmux configuration loads without syntax errors" {
  run tmux -f "$DOTFILES_DIR/.tmux.conf" new-session -d -s bats-tmux-check
  [ "$status" -eq 0 ]
  tmux kill-session -t bats-tmux-check 2>/dev/null || true
}

@test "configs: neovim starts and exits cleanly headlessly" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed in this environment"
  fi
  run nvim --headless +qa
  [ "$status" -eq 0 ]
}

@test "configs: avante.nvim resolves to appropriate endpoint based on role" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed in this environment"
  fi
  local expected="http://mac-node:1234/v1"
  if [ -f "$HOME/.config/dotfiles/role" ] && [ "$(cat "$HOME/.config/dotfiles/role")" = "host" ]; then
    expected="http://127.0.0.1:1234/v1"
  fi
  run nvim --headless -c "lua local cfg = require('avante.config'); assert(cfg.providers.deepseek.endpoint == '$expected', 'Expected $expected, got: ' .. cfg.providers.deepseek.endpoint)" +qa
  [ "$status" -eq 0 ]
}

@test "configs: btop config enables vim keys and tomorrow-night theme" {
  run grep 'vim_keys = true' "$DOTFILES_DIR/.config/btop/btop.conf"
  [ "$status" -eq 0 ]

  run grep 'color_theme = "tomorrow-night"' "$DOTFILES_DIR/.config/btop/btop.conf"
  [ "$status" -eq 0 ]
}

@test "configs: bat config uses base16 theme" {
  run grep 'theme="base16"' "$DOTFILES_DIR/.config/bat/config"
  [ "$status" -eq 0 ]
}


