#!/usr/bin/env bash

# Turn off PC screens
xrandr --output VGA-1 --off

# Turn off DPMS which blanks the screen after 5 minutes of inactivity
xset s off -dpms

# Set TV as main output
xrandr --output HDMI-0 --mode 1600x900 --left-of VGA-1

# Remotely turn on the TV via the HDMI cable
echo "on 1" | sudo cec-client -s /dev/ttyACM0

# Set a random wallpaper as background on the TV for now
feh --randomize --bg-fill "$HOME/.config/wallpapers/*"
