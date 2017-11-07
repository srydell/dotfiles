#
# ~/.bashrc
#

# Colorscheme
source "$HOME/.vim/pack/minpac/opt/gruvbox/gruvbox_256palette.sh"

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

# Auto expand history substitution
bind Space:magic-space

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Make vim default editor
export VISUAL=vim
export EDITOR=$VISUAL

# Counteracting a bug in systemd according to archlinux.org forum. Found in application "i3lock"
export LC_ALL=en_US.UTF-8

# Make bash compiling use ccache and all cores. Check #Cores by lscpu
export PATH="/usr/lib/ccache/bin/:$PATH"
export MAKEFLAGS="-j13 -l12"
