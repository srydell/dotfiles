-- Pure-Lua replacement for cpp.lua's old vim-errorformat-based parsing.
--
-- Built on overseer's `parselib` (:help overseer-parsing), which lets each
-- diagnostic shape be expressed as a small Lua-pattern matcher instead of
-- one opaque errorformat string. Every piece below is a plain function you
-- can call directly with a line of text -- see cpp_parser_spec.lua -- with
-- no vim.fn.getqflist/errorformat plumbing required to test it.
--
-- Wire this up with the `on_output_parse` + `on_result_diagnostics_quickfix`
-- components (instead of `on_output_quickfix`, which only understands
-- errorformat strings).
local parselib = require('overseer.parselib')
local files = require('overseer.files')

local M = {}

-- Modern clang/gcc diagnostics with a column, e.g.:
--   src/foo.cpp:12:5: error: use of undeclared identifier 'x'
--   src/foo.cpp:20:10: warning: unused variable 'y' [-Wunused-variable]
M.parse_diagnostic_with_column = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^([^:%s]+):(%d+):(%d+): (%a+): (.+)$'),
  { 'filename', 'lnum', 'col', 'type', 'text' }
)

-- Same diagnostics without a column (older gcc / some linker-stage messages), e.g.:
--   src/foo.cpp:12: error: 'x' was not declared in this scope
-- The filename must exclude ':' (never appears in real paths here) so this
-- doesn't also match "with column" lines by swallowing ":12:5" as if "12:5"
-- were the whole line number.
M.parse_diagnostic_no_column = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^([^:%s]+):(%d+): (%a+): (.+)$'),
  { 'filename', 'lnum', 'type', 'text' }
)

-- Undefined-reference style linker errors emitted by `ld` after a failed
-- clang++/g++ link step, e.g.:
--   src/foo.cpp:(.text+0x1a): undefined reference to `bar()'
-- There is no "error"/"warning" keyword to key off of here, so force `type`.
local parse_linker_error_raw =
  parselib.make_parse_fn(parselib.make_lua_match_fn('^([^:%s]+):%(.-%): (.+)$'), { 'filename', 'text' })
M.parse_linker_error = function(line)
  local item = parse_linker_error_raw(line)
  if item then
    item.type = 'E'
  end
  return item
end

-- GCC/clang auto-enable colored diagnostics (`-fdiagnostics-color=auto`)
-- whenever stdout/stderr is a tty -- which it is here, since these tasks
-- run through `docker exec -t`. That wraps the "error"/"warning"/"note"
-- keyword (and sometimes quoted identifiers) in ANSI SGR escape codes, e.g.:
--   file.cpp:12:5: \27[01;31m\27[Kerror: \27[m\27[Ksomething broke
-- which silently breaks every pattern above (`%a+` can't match through an
-- escape sequence), so the diagnostic is dropped entirely instead of just
-- losing some formatting. Strip any ANSI CSI sequence (`ESC [ ... <letter>`)
-- before doing anything else with a line.
M.strip_ansi = function(line)
  return (line:gsub('\27%[[%d;]*[%a]', ''))
end

-- GCC repeats "each undeclared identifier..." for every subsequent use of
-- the same bad symbol. Recognizing (and skipping) this noise avoids
-- reporting the same root cause 3 times over.
local is_first_noise_line =
  parselib.make_lua_test_fn('^%S+:%d+: error: %(Each undeclared identifier is reported only once')
local is_second_noise_line = parselib.make_lua_test_fn('^%S+:%d+: error: for each function it appears in%.%)$')
M.is_suppressed_noise = function(line)
  return is_first_noise_line(line) or is_second_noise_line(line)
end

-- Per-line diagnostic categories, tried in this order for every line that
-- isn't suppressed noise or a directory-change announcement.
local DIAGNOSTIC_PARSERS = {
  M.parse_diagnostic_with_column,
  M.parse_diagnostic_no_column,
  M.parse_linker_error,
}

-- `make`/`waf` announce directory changes while recursing into
-- subdirectories, e.g.:
--   Waf: Entering directory `/home/user/build/debug'
--   make[1]: Leaving directory '/home/user/build'
-- Returns 'enter'|'leave', directory  for a matching line, or nil otherwise.
-- This replaces vim errorformat's %D/%X directives so that relative
-- filenames in later diagnostics resolve against the right directory.
M.match_directory_change = function(line)
  local dir = line:match("^%S+:? ?Entering directory [`'](.+)['`]$")
  if dir then
    return 'enter', dir
  end
  dir = line:match("^%S+:? ?Leaving directory [`'](.+)['`]$")
  if dir then
    return 'leave', dir
  end
  return nil
end

-- Build a fresh overseer.OutputParser (see overseer.parselib) that tracks
-- directory context and resolves each diagnostic's filename against it.
--
-- Note: this never bumps `result_version`, so (unlike the old
-- `tail = true` errorformat setup) diagnostics are only surfaced once, from
-- the fully-buffered output at task completion -- not from raw in-progress
-- chunks, which is where pty/ANSI-driven false positives used to sneak in.
M.new_parser = function()
  local dir_stack = {}
  local diagnostics = {}

  local function resolve_filename(item)
    local dir = dir_stack[#dir_stack]
    if item.filename and dir and not files.is_absolute(item.filename) then
      item.filename = vim.fs.joinpath(dir, item.filename)
    end
    return item
  end

  return {
    parse = function(_, line)
      line = M.strip_ansi(line)
      local change, dir = M.match_directory_change(line)
      if change == 'enter' then
        table.insert(dir_stack, dir)
        return
      elseif change == 'leave' then
        -- Pop back through (and including) the matching directory, in case
        -- we ever get out of sync (make/waf are well-behaved, but be safe).
        for i = #dir_stack, 1, -1 do
          if dir_stack[i] == dir then
            for _ = i, #dir_stack do
              table.remove(dir_stack)
            end
            break
          end
        end
        return
      end

      if M.is_suppressed_noise(line) then
        return
      end

      for _, parser in ipairs(DIAGNOSTIC_PARSERS) do
        local item = parser(line)
        if item then
          table.insert(diagnostics, resolve_filename(item))
          return
        end
      end
    end,
    get_result = function()
      return { diagnostics = diagnostics }
    end,
    reset = function()
      dir_stack = {}
      diagnostics = {}
    end,
  }
end

return M
