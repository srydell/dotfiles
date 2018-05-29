#!/usr/bin/env bash
# This is a modified version of a snippet by u/wiley_times on reddit

# Combined with the i3 option
# for_window [instance="scratch"] floating enable;
# This script will open a floating window with vim running inside.
# When saved and exited, the text will be put inside the last focused window.
# Can be used to write posts, comments etc from vim.

_INPUT_FILE=$(mktemp)

# i3 will make this a scratch window based on the class.
urxvt -name "scratch" -e vim -c "set noswapfile | set filetype=markdown" "$_INPUT_FILE"
sleep 0.2

# Strip last byte, the newline. https://stackoverflow.com/a/12579554
head -c -1 $_INPUT_FILE | xdotool type --clearmodifiers --delay 0 --file -

# Cleanup
rm $_INPUT_FILE
