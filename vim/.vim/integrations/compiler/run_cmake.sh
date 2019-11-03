#!/bin/sh
## Maintainer: Simon Rydell

# Default options
c_compiler="clang"
cxx_compiler="clang++"
generator="Ninja"
build_type="Release"
cmake_extra_args=""
for option in "$@"
do
	# Shift once to the option value,
	# and then once past it
	case $option in
		--compiler )
			shift
			compiler="$1"
			# Only do for gcc since clang is default
			case $compiler in
				gcc )
					c_compiler="gcc"
					cxx_compiler="g++"
			esac
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
		--cmake_extra_args )
			shift
			cmake_extra_args="$1"
			shift
			;;
	esac
done

# Full path of the supplied compiler
c_compiler=$(command -v "$c_compiler")
cxx_compiler=$(command -v "$cxx_compiler")

# CMake options
# Example:
#    generator = Ninja
#    build_type = Release
#    compiler = clang++
cmake_compiler_args="-D CMAKE_CXX_COMPILER=$cxx_compiler -D CMAKE_CXX_COMPILER=$c_compiler"
cmake -S. -Bbuild -G "$generator" -D CMAKE_BUILD_TYPE="$build_type" "$cmake_compiler_args" "$cmake_extra_args"> /dev/null || exit

# Link the database
if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi
