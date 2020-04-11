#!/bin/sh
## Maintainer: Simon Rydell
## Date created: Nov 01, 2019

cd ~/bin || exit

if [ ! -d ~/bin/elixir-ls ]; then
	git clone git@github.com:elixir-lsp/elixir-ls.git
fi

cd ~/bin/elixir-ls || exit

git pull

# Where all the executables will rely
mkdir release

# Build dependencies
mix deps.get || exit

# Build the LS
mix compile || exit

# Put the release build in release
mix elixir_ls.release -o release
