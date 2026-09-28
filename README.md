# dotfiles

Personal developer environment configuration for macOS on Apple Silicon.

## Quick Start (Fresh Machine)

```bash
# 1. Clone repository
git clone git@github.com:flyingrobots/dotfiles.git ~/git/dotfiles

# 2. Run symlink installer (safely backs up any existing configs)
~/git/dotfiles/install.sh

# 3. Install packages from Brewfile
brew bundle --file=~/git/dotfiles/Brewfile
```

## Structure

```text
~/git/dotfiles/
├── .zshrc                  # Zsh shell configuration (fast completion, autosuggestions, starship)
├── .zshenv                 # Environment variables and PATH exports
├── .zprofile               # Login profile hooks
├── .tmux.conf              # Tmux session management & vim split integration
├── .gitconfig              # Git configuration with SSH signing and delta pager
├── .config/
│   ├── ghostty/config      # GPU terminal config (Monaspace Radon NF, ligatures, tabs)
│   ├── starship.toml       # Cross-shell prompt configuration
│   ├── btop/btop.conf      # System monitor theme & refresh rates
│   └── nvim/               # Neovim (LazyVim, Avante.nvim with local LLM integration)
├── .local/bin/
│   ├── ask                 # Dual-brain local LLM query tool (DeepSeek-R1 + Gemma)
│   └── tmux-sessionizer    # Fuzzy project navigation (Ctrl-F)
├── launchd/
│   └── ai.lmstudio.server.plist # Auto-start LM Studio headless server on login
├── Brewfile                # Complete Homebrew manifest (CLI tools, fonts, casks)
└── install.sh              # Idempotent symlink installation script
```

## Features

- **Terminal**: [Ghostty](https://ghostty.org/) with `Monaspace Radon NF` + code ligatures (`calt`, `ss01`-`ss10`, `liga`).
- **Prompt**: [Starship](https://starship.rs/) configured for sub-110ms startup.
- **AI Tooling**: Local LLM dual-routing via [LM Studio](https://lmstudio.ai/) (`DeepSeek-R1 32B` + `Gemma 4-e4b`) in `ask` CLI and `avante.nvim`.
- **Navigation**: Instant fuzzy project switching via `tmux-sessionizer` (`Ctrl-F`), `zoxide`, and global `cdpath`.
