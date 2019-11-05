#!/bin/sh
## Maintainer: Simon Rydell

# Default options
# NOTE: Compiler only needs to be clang/gcc,
#       the script handles for C++ etc
compiler="clang"
generator="Ninja"
build_type="Release"
cores=2

# Options to tweak
# Will be passed when creating the build files
cmake_extra_args=""
# Name of the exe, without path
executable=""
# extra arguments for the exe
exe_args=""

while [ -n "$*" ]
do
	# Shift once to the option value,
	# and then once past it
	case $1 in
		--compiler )
			shift
			compiler="$1"
			shift
			continue
			;;
		--generator )
			shift
			generator="$1"
			shift
			continue
			;;
		--build_type )
			shift
			build_type="$1"
			shift
			continue
			;;
		--cores )
			shift
			cores="$1"
			shift
			continue
			;;
		--executable )
			shift
			executable="$1"
			shift
			continue
			;;
		--extra_cmake_args )
			shift
			cmake_extra_args="$1"
			shift
			continue
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			exe_args="$*"
			break
	esac
done

~/.vim/integrations/compiler/run_cmake.sh --compiler "$compiler" --generator "$generator" --build_type "$build_type" "$cmake_extra_args" > /dev/null || exit

# Build libraries and executables
cmake --build build -j "$cores" || exit

# Run executable if found
for exe in ./build/bin/$executable ./build/$executable
do
	if [ -x "$exe" ]; then
		$exe $exe_args
		exit
	fi
done
