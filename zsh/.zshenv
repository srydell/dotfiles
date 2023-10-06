export ZDOTDIR=$HOME/.zsh

if [ -f ~/.secrets ]; then
	source ~/.secrets
fi

# Use vim as a manpager. Read from stdin.
# NOTE: The settings are written in the corresponding ftplugin
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set filetype=man' -\""

# Make vim default editor
export VISUAL=nvim
export EDITOR=$VISUAL

export LC_ALL=en_US.UTF-8

# Let fzf fuzzy finder use ripgrep to search for the files.
# This respects .gitignore and the like
export FZF_DEFAULT_COMMAND='rg --files'

export GOPATH="$HOME/.go"
export PATH="$PATH:$GOPATH/bin"
# Place for custom scripts
export PATH="$HOME/bin:$PATH"
# Place for custom executables used by vim
export PATH="$PATH:$HOME/.vim/integrations/bin"
# Fuzzy finder binary
export PATH="$HOME/.vim/pack/minpac/start/fzf/bin/:$PATH"

# Set config path
export XDG_CONFIG_HOME=$HOME/.config

# pip
export PATH="$PATH:$HOME/.local/bin"
