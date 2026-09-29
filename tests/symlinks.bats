#!/usr/bin/env bats

setup() {
  DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
}

@test "symlinks: core shell configs are symlinked to repository" {
  [ -L "$HOME/.zshrc" ]
  [ "$(readlink "$HOME/.zshrc")" = "$DOTFILES_DIR/.zshrc" ]

  [ -L "$HOME/.zshenv" ]
  [ "$(readlink "$HOME/.zshenv")" = "$DOTFILES_DIR/.zshenv" ]

  [ -L "$HOME/.zprofile" ]
  [ "$(readlink "$HOME/.zprofile")" = "$DOTFILES_DIR/.zprofile" ]
}

@test "symlinks: git and tmux configs are symlinked" {
  [ -L "$HOME/.gitconfig" ]
  [ "$(readlink "$HOME/.gitconfig")" = "$DOTFILES_DIR/.gitconfig" ]

  [ -L "$HOME/.tmux.conf" ]
  [ "$(readlink "$HOME/.tmux.conf")" = "$DOTFILES_DIR/.tmux.conf" ]
}

@test "symlinks: .config tools (ghostty, starship, btop, nvim) are symlinked" {
  [ -L "$HOME/.config/ghostty/config" ]
  [ "$(readlink "$HOME/.config/ghostty/config")" = "$DOTFILES_DIR/.config/ghostty/config" ]

  [ -L "$HOME/.config/starship.toml" ]
  [ "$(readlink "$HOME/.config/starship.toml")" = "$DOTFILES_DIR/.config/starship.toml" ]

  [ -L "$HOME/.config/btop/btop.conf" ]
  [ "$(readlink "$HOME/.config/btop/btop.conf")" = "$DOTFILES_DIR/.config/btop/btop.conf" ]

  [ -L "$HOME/.config/bat/config" ]
  [ "$(readlink "$HOME/.config/bat/config")" = "$DOTFILES_DIR/.config/bat/config" ]

  [ -L "$HOME/.config/nvim" ]
  [ "$(readlink "$HOME/.config/nvim")" = "$DOTFILES_DIR/.config/nvim" ]
}

@test "symlinks: .local/bin tools (ask, tmux-sessionizer) are symlinked and executable" {
  [ -L "$HOME/.local/bin/ask" ]
  [ "$(readlink "$HOME/.local/bin/ask")" = "$DOTFILES_DIR/.local/bin/ask" ]
  [ -x "$HOME/.local/bin/ask" ]

  [ -L "$HOME/.local/bin/tmux-sessionizer" ]
  [ "$(readlink "$HOME/.local/bin/tmux-sessionizer")" = "$DOTFILES_DIR/.local/bin/tmux-sessionizer" ]
  [ -x "$HOME/.local/bin/tmux-sessionizer" ]
}

@test "symlinks: active role zshrc.local is linked to client role" {
  [ -L "$HOME/.zshrc.local" ]
  [ "$(readlink "$HOME/.zshrc.local")" = "$DOTFILES_DIR/roles/client/zshrc.role" ]
}
