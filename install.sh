#!/usr/bin/env bash
# ==============================================================================
# dotfiles bootstrap and role-aware idempotent installer
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

MIN_HOST_RAM_GB=64

info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m ✔︎\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m ⚠\033[0m %s\n" "$*"; }
err()   { printf "\033[1;31m ✖\033[0m %s\n" "$*" >&2; }

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

# ------------------------------------------------------------------------------
# 1. Hardware Probe & Guardrails
# ------------------------------------------------------------------------------
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

CAN_BE_HOST=0
if [ "$RAM_GB" -ge "$MIN_HOST_RAM_GB" ] && [[ ! "$LOCAL_HOSTNAME" =~ [Bb]ook ]] && [[ ! "$MODEL_NAME" =~ [Bb]ook ]]; then
    CAN_BE_HOST=1
fi

# ------------------------------------------------------------------------------
# 2. Parse CLI Options
# ------------------------------------------------------------------------------
CHOSEN_ROLE=""
SKIP_BREW=0

for arg in "$@"; do
    case "$arg" in
        --client|-c|client)
            CHOSEN_ROLE="client"
            ;;
        --host|-h|host)
            CHOSEN_ROLE="host"
            ;;
        --no-brew|--skip-brew)
            SKIP_BREW=1
            ;;
        --help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --client, -c, client   Install client profile (Satellite / Laptop)"
            echo "  --host,   -h, host     Install host profile (Workstation / 64GB+ server)"
            echo "  --no-brew, --skip-brew Skip Homebrew package bundle check"
            echo "  --help                 Show this help message"
            exit 0
            ;;
        *)
            warn "Unknown argument '$arg' ignored"
            ;;
    esac
done

check_host_eligibility() {
    if [ "$CAN_BE_HOST" -ne 1 ]; then
        printf "\n"
        err "Host profile REFUSED on this device!"
        echo "   Device:       $LOCAL_HOSTNAME ($MODEL_NAME)"
        echo "   Physical RAM: ${RAM_GB} GB (Minimum required for host: ${MIN_HOST_RAM_GB} GB)"
        echo ""
        echo "   The 'host' profile runs local 32B+ LLM inference servers (DeepSeek-R1 + Gemma)."
        echo "   This hardware cannot support host workloads without severe thrashing or crashing."
        echo "   Please use '--client' on this machine."
        echo ""
        exit 1
    fi
}

# Interactive role prompt if not specified
if [ -z "$CHOSEN_ROLE" ]; then
    info "Hardware Probe:"
    printf "   Device:   \033[1m%s\033[0m (%s)\n" "$LOCAL_HOSTNAME" "$MODEL_NAME"
    printf "   Memory:   \033[1m%d GB\033[0m unified memory\n" "$RAM_GB"

    if [ "$CAN_BE_HOST" -eq 1 ]; then
        printf "   Detected: \033[1;32mHost / Workstation capable\033[0m (>= %d GB RAM)\n\n" "$MIN_HOST_RAM_GB"
        echo "Select role to install:"
        echo "  [1] Host   (Workstation - Local 32B+ model daemon, server profile) [Default]"
        echo "  [2] Client (Satellite   - Remote LM Studio via MagicDNS, client aliases)"
        printf "Select role [1/2] (Default: 1): "
        read -r choice || choice=""
        if [ "$choice" = "2" ]; then
            CHOSEN_ROLE="client"
        else
            CHOSEN_ROLE="host"
        fi
    else
        printf "   Detected: \033[1;36mClient / Satellite\033[0m (< %d GB RAM or portable device)\n\n" "$MIN_HOST_RAM_GB"
        echo "Select role to install:"
        echo "  [1] Client (Satellite   - Remote LM Studio via MagicDNS, client aliases) [Default]"
        printf "  [2] Host   (\033[1;31mBLOCKED\033[0m - Requires >= %d GB RAM, found %d GB)\n" "$MIN_HOST_RAM_GB" "$RAM_GB"
        printf "Select role [1/2] (Default: 1): "
        read -r choice || choice=""
        if [ "$choice" = "2" ]; then
            check_host_eligibility
        fi
        CHOSEN_ROLE="client"
    fi
fi

if [ "$CHOSEN_ROLE" = "host" ]; then
    check_host_eligibility
fi

info "Configuring profile: \033[1;35m$CHOSEN_ROLE\033[0m"

# ------------------------------------------------------------------------------
# 3. Homebrew & CLI Tooling Check (Idempotent)
# ------------------------------------------------------------------------------
if [ "$SKIP_BREW" -eq 0 ]; then
    if ! command -v brew >/dev/null 2>&1; then
        if [ -x "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            warn "Homebrew not found. Please install Homebrew: https://brew.sh"
        fi
    fi

    if command -v brew >/dev/null 2>&1; then
        info "Checking Homebrew packages from Brewfile..."
        if brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
            ok "Homebrew packages and casks already satisfied."
        else
            info "Installing/updating packages from Brewfile..."
            brew bundle install --file="$DOTFILES_DIR/Brewfile" || warn "Some brew packages encountered warnings during install"
        fi
    fi
else
    info "Skipping Homebrew bundle check (--no-brew)"
fi

# ------------------------------------------------------------------------------
# 4. OrbStack Container Runtime Check (Idempotent)
# ------------------------------------------------------------------------------
if [ "$SKIP_BREW" -eq 0 ]; then
    if ! command -v orbctl >/dev/null 2>&1 && [ ! -d "/Applications/OrbStack.app" ]; then
        info "Installing OrbStack container runtime..."
        brew install --cask orbstack
        ok "OrbStack installed"
    else
        ok "OrbStack container runtime already installed."
    fi

    # Ensure OrbStack engine is active
    if command -v orbctl >/dev/null 2>&1; then
        if ! orbctl status 2>/dev/null | grep -q "Running"; then
            info "Starting OrbStack container engine..."
            orbctl start >/dev/null 2>&1 || true
        fi
        ok "OrbStack container engine is active."
    fi
fi

# ------------------------------------------------------------------------------
# 4. Core Dotfiles Symlinks (Idempotent)
# ------------------------------------------------------------------------------
info "Linking core dotfiles to $HOME..."

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
link_file "$DOTFILES_DIR/.config/bat/config" "$HOME/.config/bat/config"
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

# ------------------------------------------------------------------------------
# 5. Git SSH Signing Setup (Idempotent)
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/allowed_signers"
chmod 600 "$HOME/.ssh/allowed_signers"

for key_candidate in "$HOME/.ssh/id_github.pub" "$HOME/.ssh/id_ed25519.pub"; do
    if [ -f "$key_candidate" ]; then
        key_content="$(cat "$key_candidate")"
        if ! grep -q -F "$key_content" "$HOME/.ssh/allowed_signers" 2>/dev/null; then
            info "Registering $(basename "$key_candidate") in ~/.ssh/allowed_signers..."
            printf "%s %s\n" "james@flyingrobots.dev" "$key_content" >> "$HOME/.ssh/allowed_signers"
            ok "Added $(basename "$key_candidate") to allowed_signers."
        fi
    fi
done
ok "Git SSH allowed_signers verified."

# ------------------------------------------------------------------------------
# 6. Neovim & Lazy Plugins Bootstrap (Idempotent)
# ------------------------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
    ok "Neovim configuration linked."
    if [ -f "$HOME/.local/share/nvim/lazy/avante.nvim/build.sh" ] && [ ! -f "$HOME/.local/share/nvim/lazy/avante.nvim/lua/avante_repo_map.so" ]; then
        info "Fetching Avante.nvim prebuilt native libraries..."
        (cd "$HOME/.local/share/nvim/lazy/avante.nvim" && bash build.sh >/dev/null 2>&1 || true)
        ok "Avante native libraries ready."
    fi
fi

# ------------------------------------------------------------------------------
# 7. Tmux Plugins (tmux-resurrect & tmux-continuum)
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.tmux/plugins"
if [ ! -d "$HOME/.tmux/plugins/tmux-resurrect" ]; then
    info "Installing tmux-resurrect..."
    git clone --depth 1 https://github.com/tmux-plugins/tmux-resurrect "$HOME/.tmux/plugins/tmux-resurrect" >/dev/null 2>&1 || true
    ok "Installed tmux-resurrect"
else
    ok "tmux-resurrect already installed."
fi

if [ ! -d "$HOME/.tmux/plugins/tmux-continuum" ]; then
    info "Installing tmux-continuum..."
    git clone --depth 1 https://github.com/tmux-plugins/tmux-continuum "$HOME/.tmux/plugins/tmux-continuum" >/dev/null 2>&1 || true
    ok "Installed tmux-continuum"
else
    ok "tmux-continuum already installed."
fi

# ------------------------------------------------------------------------------
# 8. Python & uv Tools Setup (Idempotent)
# ------------------------------------------------------------------------------
if command -v uv >/dev/null 2>&1; then
    if [ ! -x "$HOME/.local/bin/python3" ]; then
        info "Installing Python 3.13 via uv..."
        uv python install 3.13 >/dev/null 2>&1 || true
        py_bin=$(find "$HOME/.local/share/uv/python" -name "python3.13" -type f 2>/dev/null | head -1 || true)
        if [ -n "$py_bin" ]; then
            ln -sf "$py_bin" "$HOME/.local/bin/python3.13"
            ln -sf "$HOME/.local/bin/python3.13" "$HOME/.local/bin/python3"
            ln -sf "$HOME/.local/bin/python3.13" "$HOME/.local/bin/python"
        fi
        ok "Configured Python 3.13 in ~/.local/bin"
    else
        ok "Python 3.13 already present in ~/.local/bin"
    fi

    for py_tool in ruff pynvim; do
        if uv tool list 2>/dev/null | grep -q "^$py_tool "; then
            ok "uv tool '$py_tool' already installed."
        else
            info "Installing uv tool: $py_tool..."
            uv tool install "$py_tool" >/dev/null 2>&1 || true
            ok "Installed uv tool '$py_tool'"
        fi
    done
fi

# ------------------------------------------------------------------------------
# 9. Node & DevContainer Tools (Idempotent)
# ------------------------------------------------------------------------------
if command -v npm >/dev/null 2>&1; then
    for npm_pkg in "@devcontainers/cli" "neovim"; do
        if npm list -g "$npm_pkg" >/dev/null 2>&1; then
            ok "npm package '$npm_pkg' already installed."
        else
            info "Installing global npm package: $npm_pkg..."
            npm install -g "$npm_pkg" >/dev/null 2>&1 || true
            ok "Installed npm package '$npm_pkg'"
        fi
    done
fi

# ------------------------------------------------------------------------------
# 10. Role Specialization (Idempotent)
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.config/dotfiles"
echo "$CHOSEN_ROLE" > "$HOME/.config/dotfiles/role"

if [ "$CHOSEN_ROLE" = "client" ]; then
    info "Applying Client role configurations..."
    link_file "$DOTFILES_DIR/roles/client/zshrc.role" "$HOME/.zshrc.local"

    # Ensure background LM Studio daemon is not running on client
    if [ -f "$HOME/Library/LaunchAgents/ai.lmstudio.server.plist" ]; then
        warn "Disabling LM Studio LaunchAgent on client device..."
        launchctl unload "$HOME/Library/LaunchAgents/ai.lmstudio.server.plist" 2>/dev/null || true
        rm -f "$HOME/Library/LaunchAgents/ai.lmstudio.server.plist"
    fi
    ok "Client role active: inference routed to mac-node via Tailscale."

elif [ "$CHOSEN_ROLE" = "host" ]; then
    info "Applying Host role configurations..."
    link_file "$DOTFILES_DIR/roles/host/zshrc.role" "$HOME/.zshrc.local"

    # Install and load LaunchAgent daemon for LM Studio
    if [ -d "$DOTFILES_DIR/launchd" ]; then
        mkdir -p "$HOME/Library/LaunchAgents"
        for plist in "$DOTFILES_DIR/launchd/"*.plist; do
            if [ -f "$plist" ]; then
                base="$(basename "$plist")"
                sed "s|__HOME__|$HOME|g" "$plist" > "$HOME/Library/LaunchAgents/$base"
                launchctl unload "$HOME/Library/LaunchAgents/$base" 2>/dev/null || true
                launchctl load -w "$HOME/Library/LaunchAgents/$base" 2>/dev/null || true
            fi
        done
        ok "Host LaunchAgents installed and running."
    fi
fi

printf "\n\033[1;32m✔ Dotfiles installation complete!\033[0m (%s profile active)\n" "$CHOSEN_ROLE"
echo "  Run 'make test' to verify shell syntax and network endpoints."
