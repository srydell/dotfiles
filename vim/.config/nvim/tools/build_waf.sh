#!/bin/bash

if [ "$1" = "all" ]; then
  echo "Building all targets"
  source "$PWD/build/debug/conanbuild.sh"

  # NOTE: 2>&1 pipes stderr to stdout
  waf 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

  # Make sure the exit code status is the first in the latest pipe
  exit "${PIPESTATUS[0]}"
elif [ "$*" = "test all" ]; then
  echo "Building and running all tests"
  source "$PWD/build/debug/conanbuild.sh"

  waf test 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'
  exit "${PIPESTATUS[0]}"
fi

source "$PWD/build/debug/conanbuild.sh"

echo "Building target: $1"

# NOTE: 2>&1 pipes stderr to stdout
waf --target="$1" 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

build_exit_code=${PIPESTATUS[0]}
if [ "${build_exit_code}" -ne 0 ]; then
  exit "${build_exit_code}"
fi

# Run the built target if it's a unit_test
if [[ $1 == unit_test* ]]; then
  "$1" | sed 's@\.\.\/\.\.@'"$PWD"'@g'

  # Make sure the exit code status is the first in the latest pipe
  exit "${PIPESTATUS[0]}"
fi
