if [ -z "$1" ]; then
  echo "No target given. Please provide an argument to the script"
  exit 1
fi

source "$PWD/build/debug/conanbuild.sh"

echo "Building target: $1"

# NOTE: 2>&1 pipes stderr to stdout
waf --target="$1" 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

# If the exit code of waf failed, exit with it
if (("${PIPESTATUS[0]}" != "0")); then
  exit "${PIPESTATUS[0]}"
fi

# Run the built target
"$1"
