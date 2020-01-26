#!/bin/sh
## Maintainer: Simon Rydell
## Date created: Nov 13, 2019

# One of [clang++, g++]
compiler=""
# Path to file that should be compiled
path=""
# Name of the outputed executable
executable=""
executable_args=""

common_flags="\
	-Wall \
	-Werror \
	-Wextra \
	-Wshadow \
	-Wnon-virtual-dtor \
	-Wold-style-cast \
	-Wcast-align \
	-Wunused \
	-Woverloaded-virtual \
	-Wpedantic \
	-Wconversion \
	-Wsign-conversion \
	-Wnull-dereference \
	-Wdouble-promotion \
	-Wdate-time \
	-Wformat=2 \
	"

clang_flags="\
	-Wduplicate-enum \
	-fdiagnostics-absolute-paths \
	"

gcc_flags="\
	-Wmisleading-indentation \
	-Wduplicated-cond \
	-Wduplicated-branches \
	-Wlogical-op \
	-Wuseless-cast \
	"

# Save in case of error
input=$*

# Parse input
while [ -n "$*" ]
do
	# Shift once to the option value,
	# and then once past it
	case $1 in
		--compiler )
			shift
			case $1 in
				clang++ )
					compiler=$(command -v clang++)
					flags="$common_flags $clang_flags"
					break
					;;
				g++ )
					compiler=$(command -v g++)
					flags="$common_flags $gcc_flags"
					break
					;;
				* )
					echo "Unsupported compiler: $1"
					exit 1
					break
					;;
			esac
			shift
			continue
			;;
		--path )
			shift
			path="$1"
			shift
			continue
			;;
		--executable )
			shift
			executable="$1"
			shift
			continue
			;;
		* )
			# The rest of the arguments
			# are passed to the executable
			executable_args="$*"
			break
	esac
done

if [ -z "$compiler" ] || [ -z "$path" ] || [ -z "$executable" ]; then
	echo "Not enough input specified."
	echo "Input was:"
	echo "$input"
	echo "Compiler: $compiler"
	echo "Path: $path"
	echo "Executable: $executable"
	exit 1
fi

bin_dir="$PWD/build/bin"
# Create bin
if [ ! -d "$bin_dir" ]; then
	mkdir -p "$bin_dir"
fi

# Compile file to bin
$compiler -std=c++17 -O3 -o "$bin_dir/$executable" $path $flags

# If there is an executable, run it
if [ -n "$executable" ] && [ -x "$bin_dir/$executable" ]; then
	"$bin_dir/$executable" $executable_args
fi
