#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colorscheme
source "$HOME/.vim/pack/minpac/opt/gruvbox/gruvbox_256palette.sh"

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

# Correct spelling mistakes in cd commands
shopt -s cdspell

# I always have new mail, stop telling me about it
shopt -u mailwarn
unset MAILCHECK

# Set for autocompletion
shopt -s extglob

complete -A hostname   ssh scp ping disk
complete -A export     printenv
complete -A variable   export local readonly unset
complete -A enabled    builtin
complete -A alias      alias unalias
complete -A function   function
complete -A shopt      shopt

# Load the shell dotfiles if they exist.
if [ -d ~/.bash ]; then
	for file in ~/.bash/{bash_prompt,aliases,functions};
	do
		[ -r "$file" ] && [ -f "$file" ] && source "$file";
	done
fi
unset file;
