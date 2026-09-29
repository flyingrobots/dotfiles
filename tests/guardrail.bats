#!/usr/bin/env bats

setup() {
  DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
}

@test "install.sh: displays usage with --help" {
  run "$DOTFILES_DIR/install.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage: ./install.sh [OPTIONS]" ]]
  [[ "$output" =~ "--client" ]]
  [[ "$output" =~ "--host" ]]
}

@test "guardrail: refuses host profile on underpowered hardware (< 64 GB RAM)" {
  # On this machine (16 GB MacBook Air), host must be rejected
  run "$DOTFILES_DIR/install.sh" --host --no-brew
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Host profile REFUSED on this device" ]]
  [[ "$output" =~ "Minimum required for host: 64 GB" ]]
}

@test "client: succeeds with --client flag" {
  run "$DOTFILES_DIR/install.sh" --client --no-brew
  [ "$status" -eq 0 ]
  [[ "$output" =~ "client profile active" ]]
}
