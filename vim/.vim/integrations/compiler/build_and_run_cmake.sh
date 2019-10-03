#!/bin/sh
## Maintainer: Simon Rydell

# Default options
compiler="clang++"
generator="Ninja"
build_type="Release"
cores=2
# Name of the exe, without path
executable=""
exe_args=""
for option in "$@"
do
	# Shift once to the option value,
	# and then once past it
	case $option in
		--compiler )
			shift
			compiler="$1"
			shift
			;;
		--generator )
			shift
			generator="$1"
			shift
			;;
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
		--executable )
			shift
			executable="$1"
			shift
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			exe_args="$*"
	esac
done

# Full path of the supplied compiler
compiler=$(command -v "$compiler")

# CMake options
# Example:
#    generator = Ninja
#    build_type = Release
#    compiler = clang++
cmake -S. -Bbuild -G "$generator" -D CMAKE_BUILD_TYPE="$build_type" -D CMAKE_CXX_COMPILER="$compiler" > /dev/null || exit

# Build executable
cmake --build build -j "$cores" || exit

# Link the database
if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi

# Run executable if found
for exe in ./build/bin/$executable ./build/$executable
do
	if [ -x "$exe" ]; then
		$exe "$exe_args"
		exit
	fi
done
