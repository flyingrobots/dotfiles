#!/usr/bin/env bats

setup() {
  DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
}

@test "idempotency: successive install runs execute cleanly without re-linking" {
  # First pass
  run "$DOTFILES_DIR/install.sh" --client --no-brew
  [ "$status" -eq 0 ]

  # Second pass
  run "$DOTFILES_DIR/install.sh" --client --no-brew
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Already linked: $HOME/.zshrc" ]]
  [[ "$output" =~ "Already linked: $HOME/.gitconfig" ]]
  [[ "$output" =~ "Already linked: $HOME/.config/ghostty/config" ]]
  [[ "$output" =~ "Already linked: $HOME/.config/nvim" ]]
  [[ "$output" =~ "Neovim configuration linked" ]]
  if command -v uv >/dev/null 2>&1; then
    [[ "$output" =~ "uv tool 'ruff' already installed" ]]
  fi
  [[ "$output" =~ "Dotfiles installation complete!" ]]
}
