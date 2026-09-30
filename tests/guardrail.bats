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

@test "guardrail: enforces host profile hardware requirements (< 64 GB RAM)" {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    RAM_GB=$(( RAM_BYTES / 1024 / 1024 / 1024 ))
    MODEL_NAME="$(sysctl -n hw.model 2>/dev/null || echo "Unknown Mac")"
    LOCAL_HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || hostname)"
  else
    RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    RAM_GB=$(( RAM_KB / 1024 / 1024 ))
    MODEL_NAME="Linux Container"
    LOCAL_HOSTNAME="$(hostname)"
  fi

  if [ "$RAM_GB" -ge 64 ] && [[ ! "$LOCAL_HOSTNAME" =~ [Bb]ook ]] && [[ ! "$MODEL_NAME" =~ [Bb]ook ]]; then
    # On workstation (mac-desk), host profile succeeds
    run "$DOTFILES_DIR/install.sh" --host --no-brew
    [ "$status" -eq 0 ]
    [[ "$output" =~ "host profile active" ]]
  else
    # On underpowered machines or laptops (MacBook Air / Docker), host must be rejected
    run "$DOTFILES_DIR/install.sh" --host --no-brew
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Host profile REFUSED on this device" ]]
    [[ "$output" =~ "Minimum required for host: 64 GB" ]]
  fi
}

@test "client: succeeds with --client flag" {
  run "$DOTFILES_DIR/install.sh" --client --no-brew
  [ "$status" -eq 0 ]
  [[ "$output" =~ "client profile active" ]]
}
