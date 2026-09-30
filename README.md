# dotfiles

Personal developer environment configuration for macOS on Apple Silicon.

## Quick Start (Fresh Machine)

```bash
# 1. Clone repository
git clone git@github.com:flyingrobots/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

# 2. Run smart installer (auto-probes hardware & configures role)
make

# Or explicitly select target role:
make client    # Satellite / Laptop (remote inference via MagicDNS, client aliases)
make host      # Workstation (enforces >= 64 GB RAM; local model daemon)

# 3. Install packages from Brewfile
make brew

# 4. Run automated test suite
make test          # Local BATS tests (guardrails, idempotency, configs, symlinks)
make test-docker   # Isolated containerized BATS test suite via OrbStack/Docker
make check-endpoints # Verify live shell startup and remote LM Studio connection
```

## Hardware Guardrails

The installer probes system hardware before applying role configurations:
- **Host Role**: Reserved for high-memory workstations (`>= 64 GB` unified memory). Automatically sets up local `ai.lmstudio.server` daemon serving 32B+ LLMs. **Attempts to install the host role on laptops or underpowered machines (< 64 GB) are strictly blocked.**
- **Client Role**: Configures laptops/satellites to consume model inference remotely from `mac-node` over Tailscale MagicDNS (`http://mac-node:1234`), saving local battery, CPU, and RAM.

## Structure

```text
~/git/dotfiles/
├── Makefile                 # `make`, `make client`, `make host`, `make brew`, `make test`
├── install.sh               # Hardware-aware idempotent bootstrap script
├── roles/
│   ├── host/zshrc.role      # Workstation exports (local LM Studio server)
│   └── client/zshrc.role    # Client exports (Tailscale MagicDNS host, SSH aliases)
├── .zshrc                  # Zsh shell configuration (hooks ~/.zshrc.local)
├── .zshenv                 # Environment variables and PATH exports
├── .zprofile               # Login profile hooks
├── .tmux.conf              # Tmux session management & vim split integration
├── .gitconfig              # Git configuration with SSH signing and delta pager
├── .config/
│   ├── ghostty/config      # GPU terminal config (Monaspace Radon NF, ligatures, tabs)
│   ├── starship.toml       # Cross-shell prompt configuration
│   ├── btop/btop.conf      # System monitor (vim keys, tomorrow-night theme)
│   ├── bat/config          # Syntax highlighter (base16 theme, line numbers, git markers)
│   └── nvim/               # Neovim (LazyVim, Avante.nvim with Tailscale LLM integration)
├── .local/bin/
│   ├── ask                 # Dual-brain local/remote LLM query tool
│   └── tmux-sessionizer    # Fuzzy project navigation (Ctrl-F)
├── launchd/
│   └── ai.lmstudio.server.plist # Auto-start LM Studio server on login (--cors --bind 0.0.0.0)
├── tests/                  # 18 BATS unit/integration tests & Docker container harness
└── Brewfile                # Complete Homebrew manifest (CLI tools, fonts, casks)
```

## Features

- **Terminal**: [Ghostty](https://ghostty.org/) with `Monaspace Radon NF` + code ligatures (`calt`, `ss01`-`ss10`, `liga`).
- **Modern CLI Suite**: `bat` (colorized cat & manpager), `btop` (vim-navigable system monitor), `eza` (git-aware icons), `lazygit`, `delta`.
- **Fuzzy Finding (`fzf`)**: Live `bat` previews on `<Ctrl-T>`, directory tree previews on `<Alt-C>`, `tmux-sessionizer` on `<Ctrl-F>`.
- **Git Security**: Automatic SSH commit signing with verification via `~/.ssh/allowed_signers`.
- **AI Tooling**: Dual-routing via [LM Studio](https://lmstudio.ai/) in `ask` CLI and `avante.nvim` (direct localhost on Host, Tailscale MagicDNS on Client).
- **Navigation**: Instant fuzzy project switching via `tmux-sessionizer` (`Ctrl-F`), `zoxide`, and global `cdpath`.
- **Civilized Testing**: Fully automated 18-test BATS suite runnable locally (`make test`) and inside an isolated Docker container (`make test-docker`).

