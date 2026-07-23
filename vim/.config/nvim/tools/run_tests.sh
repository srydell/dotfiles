#!/usr/bin/env bash

# Run every test suite shipped with this repository.
#
# Each Neovim test receives isolated cache and state directories. The normal
# data directory remains available because it contains the installed plugins
# and parsers that this configuration's integration tests exercise.
set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-config-tests.XXXXXX")"
trap 'rm -rf -- "$temporary_root"' EXIT

passed=0
failed=0

run_test() {
  local name="$1"
  shift

  printf 'TEST  %s\n' "$name"
  if "$@"; then
    printf 'PASS  %s\n\n' "$name"
    passed=$((passed + 1))
  else
    printf 'FAIL  %s\n\n' "$name"
    failed=$((failed + 1))
  fi
}

run_neovim_test() {
  local test_file="$1"
  local test_name
  local test_root

  test_name="$(basename -- "$test_file" .lua)"
  test_root="$temporary_root/$test_name"
  mkdir -p -- "$test_root/cache" "$test_root/state"

    XDG_CONFIG_HOME="$(dirname -- "$repo_root")" \
    XDG_CACHE_HOME="$test_root/cache" \
    XDG_STATE_HOME="$test_root/state" \
    nvim --headless -u "$repo_root/init.lua" -l "$test_file"
}

shopt -s nullglob
lua_tests=("$repo_root"/tests/*.lua)
python_tests=("$repo_root"/tools/test_*.py "$repo_root"/tests/test_*.py)

for test_file in "${lua_tests[@]}"; do
  run_test "Neovim: $(basename -- "$test_file")" run_neovim_test "$test_file"
done

if ((${#python_tests[@]} > 0)); then
  # unittest discovery handles imports consistently while still running all
  # test_*.py modules found in both locations.
  if compgen -G "$repo_root/tools/test_*.py" >/dev/null; then
    run_test "Python: tools" env PYTHONPATH="$repo_root" python3 -m unittest discover -s "$repo_root/tools" -p 'test_*.py'
  fi
  if compgen -G "$repo_root/tests/test_*.py" >/dev/null; then
    run_test "Python: tests" env PYTHONPATH="$repo_root" python3 -m unittest discover -s "$repo_root/tests" -p 'test_*.py'
  fi
fi

printf 'RESULT  %d passed, %d failed\n' "$passed" "$failed"
((failed == 0))
