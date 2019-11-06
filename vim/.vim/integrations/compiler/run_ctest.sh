#!/bin/sh
## Maintainer: Simon Rydell

# Default options
cores=2

# Options to tweak
# Will be passed when creating the build files
extra_cmake_args=""
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
		--extra_cmake_args )
			shift
			extra_cmake_args="$1"
			shift
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			ctest_args="$*"
	esac
done

~/.vim/integrations/compiler/run_cmake.sh $extra_cmake_args

# Build libraries and executables
cmake --build build -j "$cores" || exit

cd ./build && ctest $ctest_args
