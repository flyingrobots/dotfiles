# dotfiles

Symlink-managed dotfiles.



## Bootstrap

On a fresh macOS machine:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/flyingrobots/dotfiles/main/install.sh)"
```

This will:
- Install Homebrew if missing (non-interactive)
- Install packages from Brewfile via `brew bundle`
- Configure fzf key bindings
- Symlink `.zshrc` (and optional extras) into `$HOME`

## Update the Brewfile (snapshot)

```sh
$HOME/git/dotfiles/brew-snapshot.sh
```

