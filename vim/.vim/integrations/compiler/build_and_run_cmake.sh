#!/bin/sh
## Maintainer: Simon Rydell

# Default options
compiler="clang++"
generator="Ninja"
build_type="Release"
cores=2

# Options to tweak
# Will be passed when creating the build files
cmake_extra_args=""
# If non-empty, it will run ctest
run_ctest=""
# Name of the exe, without path
executable=""
# extra arguments for the exe
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
		--run_ctest )
			shift
			run_ctest="$1"
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
cmake -S. -Bbuild -G "$generator" -D CMAKE_BUILD_TYPE="$build_type" -D CMAKE_CXX_COMPILER="$compiler" "$cmake_extra_args"> /dev/null || exit

# Build executable
cmake --build build -j "$cores" || exit

# Link the database
if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi

# Check if ctest variable is empty
if [ -z "$run_ctest" ]; then
	# Run executable if found
	for exe in ./build/bin/$executable ./build/$executable
	do
		if [ -x "$exe" ]; then
			$exe "$exe_args"
			exit
		fi
	done
else
	cd ./build && ctest
fi
