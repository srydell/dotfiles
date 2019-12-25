export ZDOTDIR=$HOME/.zsh

# Use vim as a manpager. Read from stdin.
# NOTE: The settings are written in the corresponding ftplugin
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set filetype=man' -\""

# Make vim default editor
export VISUAL=vim
export EDITOR=$VISUAL

export LC_ALL=en_US.UTF-8

# Let fzf fuzzy finder use ripgrep to search for the files.
# This respects .gitignore and the like
export FZF_DEFAULT_COMMAND='rg --files'

# Place for custom scripts
export PATH="$HOME/bin:$PATH"
# Place for custom executables used by vim
export PATH="$PATH:$HOME/.vim/integrations/bin"
# Fuzzy finder binary
export PATH="$HOME/.vim/pack/minpac/start/fzf/bin/:$PATH"

# Set config path
export XDG_CONFIG_HOME=$HOME/.config

# Keychain only handles the latest gpg key
# LATEST_GPGKEY=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '($1 ~ "sec") { print $5 }' | tail -n 1)
# Control ssh-agent. Only handles keys listed here.
# To add a new key, add the name of the file after id_rsa if it is in ~/.ssh/
# or give an absolute path
# eval $(keychain --eval --quiet --ignore-missing --agents gpg,ssh id_rsa "$LATEST_GPGKEY")
# unset LATEST_GPGKEY

# Always prompt for gpg password in the terminal instead of gui popup
GPG_TTY="$(tty)"
export GPG_TTY
