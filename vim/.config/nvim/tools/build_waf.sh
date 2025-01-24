source "$PWD/build/debug/conanbuild.sh"

# NOTE: 2>&1 pipes stderr to stdout
waf 2>&1 | sed 's@\.\.\/\.\.@'"$PWD"'@g'

# Make sure the exit code status is the first in the latest pipe
exit "${PIPESTATUS[0]}"
