#!/bin/sh
## Maintainer: Simon Rydell

# Default options
build_type="Release"
cores=2

# Options to tweak
# Will be passed when creating the build files
cmake_extra_args=""
ctest_args=""
for option in "$@"
do
	# Shift once to the option value,
	# and then once past it
	case $option in
		--build_type )
			shift
			build_type="$1"
			shift
			;;
		--cores )
			shift
			cores="$1"
			shift
			;;
		--cmake_extra_args )
			shift
			cmake_extra_args="$1"
			shift
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			ctest_args="$*"
	esac
done

~/.vim/integrations/compiler/run_cmake.sh --build_type="$build_type" --cmake_extra_args="$cmake_extra_args"

# Build libraries and executables
cmake --build build -j "$cores" || exit

cd ./build && ctest "$ctest_args"
