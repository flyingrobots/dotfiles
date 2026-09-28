eval "$(/opt/homebrew/bin/brew shellenv)"

# Zsh Completion System (loaded first so plugins and tools like fzf & zoxide register compdefs)
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Allow cd to resolve and autocomplete paths relative to ~ from any directory
cdpath=(~ $cdpath)
source <(fzf --zsh)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/j/.lmstudio/bin"
# End of LM Studio CLI section

export GPG_TTY=$(tty)

# Toolchain manager (mise)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Modern CLI tools
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"

# Modern aliases
alias ls="eza --icons"
alias ll="eza -lah --icons --git"
alias tree="eza --tree --icons"
alias cat="bat --paging=never"
alias v="nvim"
alias vim="nvim"
alias lg="lazygit"
alias top="btop"
alias htop="btop"
alias gpr="gh dash"

# Notifications (chime on Mac + push notification to iPhone via ntfy)
alias ding='afplay /System/Library/Sounds/Glass.aiff'
notify() {
  local msg="${1:-Task finished!}"
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
  curl -s -d "$msg" "https://ntfy.sh/flyingrobots-mac-alerts" >/dev/null 2>&1 &
}
alias ntfy="notify"

# tmux-sessionizer shortcut (Ctrl-f to jump to projects)
bindkey -s '^f' 'tmux-sessionizer\n'

# fzf integration with fd, bat, and eza
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --inline-info"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window right:60%:wrap"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons {} | head -200' --preview-window right:50%"

# DevContainer quick-start & enter
dev() {
  if [ ! -d ".devcontainer" ]; then
    echo "No .devcontainer directory found in current directory."
    return 1
  fi
  devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bash
}

# Zsh History (shared across all tabs)
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY


# Zsh plugins configuration
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Zsh plugins (syntax-highlighting must be loaded last)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Offer to attach to an active tmux session on interactive SSH login
if [[ -o interactive ]] && [[ -t 0 ]] && [[ -n "$SSH_CONNECTION" || -n "$SSH_TTY" || -n "$SSH_CLIENT" ]] && [[ -z "$TMUX" ]]; then
  if tmux has-session 2>/dev/null; then
    sessions=(${(f)"$(tmux list-sessions -F '#{session_name}')"})
    if [[ ${#sessions[@]} -eq 1 ]]; then
      local sname="${sessions[1]}"
      local sinfo
      sinfo="$(tmux list-sessions -F '#{session_windows} windows, created #{t:session_created}' -f "#{==:#{session_name},$sname}" 2>/dev/null)"
      echo "\033[1;34m==>\033[0m Found active tmux session: \033[1;36m$sname\033[0m ($sinfo)"
      read -r "choice?Attach to session '$sname'? [Y/n]: "
      if [[ ! "$choice" =~ ^[nN] ]]; then
        tmux attach-session -t "$sname"
      fi
    elif [[ ${#sessions[@]} -gt 1 ]]; then
      echo "\033[1;34m==>\033[0m Active tmux sessions:"
      for i in {1..${#sessions[@]}}; do
        local sname="${sessions[$i]}"
        local sinfo
        sinfo="$(tmux list-sessions -F '#{session_windows} windows, created #{t:session_created}' -f "#{==:#{session_name},$sname}" 2>/dev/null)"
        echo "  \033[1;36m$i)\033[0m $sname ($sinfo)"
      done
      echo ""
      read -r "choice?Attach to tmux? [1-${#sessions[@]}, 'n' for regular shell, Enter for 1]: "
      if [[ "$choice" =~ ^[nN] ]]; then
        :
      elif [[ -z "$choice" ]]; then
        tmux attach-session -t "${sessions[1]}"
      elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#sessions[@]} )); then
        tmux attach-session -t "${sessions[$choice]}"
      elif tmux has-session -t "$choice" 2>/dev/null; then
        tmux attach-session -t "$choice"
      fi
    fi
  fi
fi
