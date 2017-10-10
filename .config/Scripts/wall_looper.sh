#!/bin/bash

# Feed this script two arguments: $1 for a folder directory and $2 number of seconds per image.

# Will loop through the images, using feh to change the background every $2 seconds.

while [ 1==1 ]
	do
		for file in $1*;
		do
			sleep $2
			echo "$file"
			feh --bg-scale "$file"
			cp "$file" ~/.config/wallpaper.png
		done
	done
