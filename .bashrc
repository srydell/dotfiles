#
# ~/.bashrc


# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colorscheme
source "$HOME/.vim/pack/minpac/opt/gruvbox/gruvbox_256palette.sh"

# Control ssh-agent. Only handles keys listed here.
# To add a new key, add the name of the file after id_rsa if it is in ~/.ssh/
# or give an absolute path
eval "$(keychain --eval --quiet --agents ssh id_rsa)"

# Use vi keybindings command prompt
# For zsh, the same command is: bindkey -v
# set -o vi

# Auto expand history substitution on <Space>
bind Space:magic-space

# Disable XON/XOFF flow control
# This is otherwise turned on with C-s and off with C-q
stty -ixon

# History
# Append history from terminal on closing.
shopt -s histappend

# Record multiline commands as one command in history
shopt -s cmdhist

# Set historysize
HISTFILESIZE=100000
HISTSIZE=100000

# Don't store commands starting with spaces and duplicates in history
HISTCONTROL=ignoreboth

# Ignore some uninteresting calls
HISTIGNORE='ls:bg:fg:history'

# Record history with timestamps (easier to sort with awk/cut)
HISTTIMEFORMAT='%F %T '

# Store history after each command. Helps with recovering from crashes
PROMPT_COMMAND='history -a'

# Get completion for tmuxp commands
eval "$(_TMUXP_COMPLETE=source tmuxp)"

# Save tmuxp project config files under .tmux directory
export TMUXP_CONFIGDIR=$HOME/.tmux/tmuxp

# Use vim as a manpager. Read from stdin
export MANPAGER="vim -M +MANPAGER -"

# Hacky way of setting vim to be the manpager
# export MANPAGER="/bin/sh -c \"col -b | vim --not-a-term -c 'set ft=man ts=8 nomod nolist noma' -\""

# Set history file out of the way. Default is ~/.bash_history
if [ -d ~/.bash ]; then
	HISTFILE=~/.bash/bash_history
fi

# Make vim default editor
export VISUAL=vim
export EDITOR=$VISUAL

# Counteracting a bug in systemd according to archlinux.org forum. Found in application "i3lock"
export LC_ALL=en_US.UTF-8

# Let fzf fuzzy finder use ripgrep to search for the files.
# This respects .gitignore and the like
export FZF_DEFAULT_COMMAND='rg --files'

# Place for custom scripts
export PATH="$HOME/bin:$PATH"
# Fuzzy finder binary
export PATH="$HOME/.vim/pack/minpac/start/fzf/bin/:$PATH"
case "$(uname)" in
	Linux )
		# Make bash compiling use ccache and all cores. Check #Cores by lscpu
		export PATH="/usr/lib/ccache/bin/:$PATH"
		# Find the flags programmatically. Good for not blowing up your lesser machine :)
		LFLAG=$(grep -c '^processor' /proc/cpuinfo)
		((JFLAG=LFLAG+1))
		export MAKEFLAGS="-j$JFLAG -l$LFLAG"
		;;
	Darwin )
		# Let brew programs come first
		export PATH="/usr/local/sbin:$PATH"
		export PATH="/opt/local/bin:$PATH"
		export PATH="$HOME/.cargo/bin:$PATH"
		# Use brew version of gcc
		alias gcc=/usr/local/Cellar/gcc/8.1.0/bin/gcc-8
		;;
esac

# Load the shell dotfiles if they exist.
if [ -d ~/.bash ]; then
	for file in ~/.bash/{bash_prompt,aliases,functions};
	do
		[ -r "$file" ] && [ -f "$file" ] && source "$file";
	done
fi
unset file;
