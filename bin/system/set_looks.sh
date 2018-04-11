#!/usr/bin/env bash

# # Lighter with a grey bar
# feh --bg-scale .config/wallpapers/sarah-dorweiler_Leaf.jpg
# ~/.config/polybar/launch.sh greyBar

# # Darker with a transparent bar
# feh --bg-scale .config/wallpapers/sarah-dorweiler_Leaf.jpg
# ~/.config/polybar/launch.sh transparentBar

# # Must be called this way since it spawns a subshell I think
# POLYBAR_BG=#00222222 POLYBAR_FG=#dfdfdf .config/polybar/launch.sh transparentBar
# POLYBAR_BG=#00222222 POLYBAR_FG=#dfdfdf .config/polybar/launch.sh transparentBar

function startBar {
	case $1 in
		transparentBar )
			local background=#00222222
			local foreground=#dfdfdf
			;;
		greyBar )
			local background=#00222222
			local foreground=#dfdfdf
			;;
	esac
	# Start the polybar
	POLYBAR_BG=$background POLYBAR_FG=$foreground $HOME/.config/polybar/launch.sh $1
}

function setWallpaper {
	feh --bg-scale $HOME/.config/wallpapers/$1
}

function getNextBarAndWall {
	local IN=$1
	# Replace every "_" in $1 with " "
	arrIN=(${IN//_/ })
	echo ${arrIN[2]}
}

case $1 in
	startup )
		startBar transparentBar
		setWallpaper jorge-garcia_Raft_transparentBar_.jpg
		;;
	next )
		getNextBarAndWall jorge-garcia_Raft_transparentBar_.jpg
		echo ${arrIN[3]}
		;;
esac
