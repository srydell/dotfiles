#!/bin/sh
## Maintainer: Simon Rydell
# Creates the build files and links the compile_commands.json.
# Does not build the project itself.
# Options:
#     --compiler $compiler
#         => $compiler one of [clang, gcc]
#
#     --generator $generator
#         => $generator could be e.g. Ninja
#
#     --build_type $build_type
#         => $build_type could be e.g. Debug, Release, ...
#
#     The rest of the arguments are passed on to the cmake call

# Default options
c_compiler=""
cxx_compiler=""
generator="Ninja"
build_type="Release"
cmake_extra_args=""

while [ -n "$*" ]
do
	# Shift once to the option value,
	# and then once past it
	case $1 in
		--compiler )
			shift
			case $1 in
				gcc )
					c_compiler="$(command -v gcc)"
					cxx_compiler="$(command -v g++)"
					;;
				clang )
					c_compiler="$(command -v clang)"
					cxx_compiler="$(command -v clang++)"
					;;
			esac
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
		* )
			# The rest of the arguments
			# are passed to the cmake build
			cmake_extra_args="$*"
			break
	esac
done

# If user provided a compiler, use it, otherwise use the default or a cached one
if [ -n "$c_compiler" ] && [ -n "$cxx_compiler" ]; then
	# Full path of the supplied compiler
	c_compiler=$(command -v "$c_compiler")
	cxx_compiler=$(command -v "$cxx_compiler")
fi

# CMake options
# Example:
#    generator = Ninja
#    build_type = Release
#    cxx_compiler = clang++
#    c_compiler = clang
# NOTE: cmake_extra_args should be split, since it could contain multiple commands
cmake -S. -Bbuild -G "$generator" -DCMAKE_CXX_COMPILER="$cxx_compiler" -DCMAKE_C_COMPILER="$c_compiler" -DCMAKE_BUILD_TYPE="$build_type" $cmake_extra_args || exit

# Link the database
if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi
