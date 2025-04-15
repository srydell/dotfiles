if [ "$1" = "all" ]; then
  echo "Building all targets"
  source "$PWD/build/debug/conanbuild.sh"

  # NOTE: 2>&1 pipes stderr to stdout
  waf 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

  # Make sure the exit code status is the first in the latest pipe
  exit "${PIPESTATUS[0]}"
fi

source "$PWD/build/debug/conanbuild.sh"

echo "Building target: $1"

# NOTE: 2>&1 pipes stderr to stdout
waf --target="$1" 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

# If the exit code of waf failed, exit with it
if (("${PIPESTATUS[0]}" != "0")); then
  exit "${PIPESTATUS[0]}"
fi

# Run the built target if it's a unit_test
if [[ $1 == unit_test* ]]; then
  "$1"
fi
