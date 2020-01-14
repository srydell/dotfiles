#!/bin/sh
## Maintainer: Simon Rydell

# Default options
cores=2

# Options to tweak
ctest_args=""
for option in "$@"
do
	# Shift once to the option value,
	# and then once past it
	case $option in
		--cores )
			shift
			cores="$1"
			shift
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			ctest_args="$*"
	esac
done

# Build libraries and executables
cmake --build build -j "$cores" || exit

# catch2 likes to report relative paths from the build dir
# NOTE: That this will replace any line that starts with two dots (..) with the $PWD
#       I used commas (,) as separators to avoid interference with the forward slashes (/)
before_build_pwd=$PWD
cd ./build && ctest $ctest_args | sed -e 's,\(^\.\.\)/,'"$before_build_pwd/"','
