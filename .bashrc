#
# ~/.bashrc
#

# Load the shell dotfiles if they exist.
if [ -d ~/.bash ]; then
	for file in ~/.bash/.{bash_prompt,aliases,functions};
	do
		[ -r "$file" ] && [ -f "$file" ] && source "$file";
	done
fi
unset file;

# Colorscheme
source "$HOME/.vim/pack/minpac/opt/gruvbox/gruvbox_256palette.sh"

# Use vi keybindings command prompt
# For zsh, the same command is: bindkey -v
set -o vi

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

# Set history file out of the way. Default is ~/.bash_history
if [ -d ~/.bash ]; then
	HISTFILE=~/.bash/.bash_history
fi

# Make vim default editor
export VISUAL=vim
export EDITOR=$VISUAL

# Counteracting a bug in systemd according to archlinux.org forum. Found in application "i3lock"
export LC_ALL=en_US.UTF-8

# Make bash compiling use ccache and all cores. Check #Cores by lscpu
export PATH="/usr/lib/ccache/bin/:$PATH"
export MAKEFLAGS="-j13 -l12"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
