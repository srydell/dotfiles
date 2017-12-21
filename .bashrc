#
# ~/.bashrc
#

# Use vi keybindings command prompt
# For zsh, the same command is: bindkey -v
set -o vi

# Disable XON/XOFF flow control
# This is otherwise turned on with C-s and off with C-q
stty -ixon

# Disable beeps
setterm -bfreq 0

# Aliases
# Use fc to repeat last command
# Alternatively add " 2>/dev/null" to not
# rewrite the last command in prompt
alias sa="fc -e : -1"
# Rerun the last two commands
alias ssa="fc -e : -2 -1"
# ls with colors
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

colors=$(tput colors)

# Terminal supports 256 colours
if ((colors >= 256)); then
	# Red if root
	color_root='\[\e[38;5;88m\]'
	# Lightblue if user
	color_user='\[\e[38;5;109m\]'
	color_undo='\[\e[0m\]'

# Terminal supports only eight colours
elif ((colors >= 8)); then
    color_root='\[\e[1;31m\]'
    color_user='\[\e[1;32m\]'
    color_undo='\[\e[0m\]'

# Terminal may not support colour at all
else
    color_root=
    color_user=
    color_undo=
fi

# Check if root
if ((EUID == 0)); then
    PS1=${color_root}${PS1}${color_undo}
else
    PS1=${color_user}${PS1}${color_undo}
fi

# Auto expand history substitution on <Space>
bind Space:magic-space

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colorscheme
source "$HOME/.vim/pack/minpac/opt/gruvbox/gruvbox_256palette.sh"

# Make vim default editor
export VISUAL=vim
export EDITOR=$VISUAL

# Counteracting a bug in systemd according to archlinux.org forum. Found in application "i3lock"
export LC_ALL=en_US.UTF-8

# Make bash compiling use ccache and all cores. Check #Cores by lscpu
export PATH="/usr/lib/ccache/bin/:$PATH"
export MAKEFLAGS="-j13 -l12"
