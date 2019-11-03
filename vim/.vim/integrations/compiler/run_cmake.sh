#!/bin/sh
## Maintainer: Simon Rydell
# Creates the build files and links the compile_commands.json.
# Does not build the project itself.
# Options:
#     --compiler $compiler
#         => $compiler one of [clang, gcc]

#     --generator $generator
#         => $generator could be e.g. Ninja

#     --build_type $build_type
#         => $build_type could be e.g. Debug, Release, ...

#     --cmake_extra_args $cmake_extra_args
#         => $cmake_extra_args is sent to cmake when creating the build files

# Default options
c_compiler=""
cxx_compiler=""
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
			case $compiler in
				gcc )
					c_compiler="gcc"
					cxx_compiler="g++"
					;;
				clang )
					c_compiler="clang"
					cxx_compiler="clang++"
					;;
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

# If user provided a compiler, use it, otherwise use the default or a cached one
if [ -n "$c_compiler" ] && [ -n "$cxx_compiler" ]; then
	# Full path of the supplied compiler
	c_compiler=$(command -v "$c_compiler")
	cxx_compiler=$(command -v "$cxx_compiler")
	cmake_compiler_args="-D CMAKE_CXX_COMPILER=$cxx_compiler -D CMAKE_CXX_COMPILER=$c_compiler"
else
	cmake_compiler_args=""
fi

# CMake options
# Example:
#    generator = Ninja
#    build_type = Release
#    compiler = clang++
cmake -S. -Bbuild -G "$generator" -D CMAKE_BUILD_TYPE="$build_type" "$cmake_compiler_args" "$cmake_extra_args" > /dev/null || exit

# Link the database
if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi
