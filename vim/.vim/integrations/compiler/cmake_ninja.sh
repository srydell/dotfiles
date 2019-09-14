#!/bin/sh
## Maintainer: Simon Rydell
## Date created: Sep 11, 2019

cmake -S. -Bbuild -G Ninja -D CMAKE_BUILD_TYPE=Debug -D CMAKE_CXX_COMPILER="$(command -v clang++)" > /dev/null || exit
# cmake options: Debug and using clang++

# Build executable
cmake --build build -j "$2" || exit

# Link the database
# if [ ! -f "$PWD/compile_commands.json" ] && [ -f "$PWD/build/compile_commands.json" ]; then
# 	ln -s "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
# fi
if [ -f "$PWD/build/compile_commands.json" ]; then
	cp "$PWD/build/compile_commands.json" "$PWD/compile_commands.json"
fi

# Run executable if found
for f in ./build/bin/$1 ./build/$1
do
	if [ -x "$f" ]; then
		$f
		exit
	fi
done
