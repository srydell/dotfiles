#!/bin/sh
## Maintainer: Simon Rydell

# Exit on any error
set -o errexit
# Print and exit on undefined variable
set -o nounset
# Stop if any command in a pipe fails
set -o pipefail

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
cmake --build build -j "$cores"

# catch2 likes to report relative paths from the build dir
# NOTE: That this will replace any line that starts with two dots (..) with the $PWD
#       I used commas (,) as separators to avoid interference with the forward slashes (/)
cd ./build && ctest $ctest_args | sed -e 's/^\.\./\./g'
