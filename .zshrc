# Docker Desktop: CLI completions
fpath=(/Users/james/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# History & zsh options
export HISTFILE="$HOME/.zsh_history"
export HISTFILE="$HOME/.zsh_history"
export HISTFILE="$HOME/.zsh_history"
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt hist_ignore_all_dups hist_ignore_space share_history inc_append_history extended_glob autocd

# Optional env file
# . "$HOME/.local/bin/env"
[ -f "$HOME/.config/secrets.zsh" ] && source "$HOME/.config/secrets.zsh"

# Helpers
git-diff-copy() {
    git add --all && git diff --staged | pbcopy && git reset
}

git-stage() {
  ADD="Add"
  RESET="Reset"
  ACTION=$(gum choose "$ADD" "$RESET")
  if [ "$ACTION" = "$ADD" ]; then
      git status --short | cut -c 4- | gum choose --no-limit | xargs git add
  else
      git status --short | cut -c 4- | gum choose --no-limit | xargs git restore
  fi
}

# Prompt
eval "$(starship init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# GPG
export GPG_TTY=$(tty)

# eza aliases (you override plain ls here intentionally)
alias ls='eza --color=always --group-directories-first --icons'
alias ll='eza -la --icons --octal-permissions --group-directories-first'
alias l='eza -bGF --header --git --color=always --group-directories-first --icons'
alias llm='eza -lbGd --header --git --sort=modified --color=always --group-directories-first --icons'
alias la='eza --long --all --group --group-directories-first'
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons'
alias lS='eza -1 --color=always --group-directories-first --icons'
alias lt='eza --tree --level=2 --color=always --group-directories-first --icons'
alias l.='eza -a | grep -E "^\."'

# Shiplog
export SHIPLOG_HOME="$HOME/.shiplog"
export PATH="$SHIPLOG_HOME/bin:$PATH"

# Homebrew toolchain paths
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# fzf
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
# Extra fzf config
[ -f "$HOME/.fzf-extra.zsh" ] && source "$HOME/.fzf-extra.zsh"
# CLI goodies
[ -f "$HOME/.cli-goodies.zsh" ] && source "$HOME/.cli-goodies.zsh"
# mise (runtime manager)
if command -v mise >/dev/null 2>&1; then eval "$(/opt/homebrew/bin/mise activate zsh)"; fi
