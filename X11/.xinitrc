# ~/.xinitrc
# This file is sourced when running startx and
#    other programs which call xinit

# Load Xresources if it exists
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources

exec i3
