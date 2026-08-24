-- Pure-Lua replacement for python.lua's old vim-errorformat-based parsing.
-- Built on overseer.parselib (see cpp_parser.lua for the pattern this
-- follows). Handles the standard CPython traceback frame line, e.g.:
--   File "/private/tmp/pytest.py", line 3, in <module>
-- The exception line itself (e.g. "ValueError: boom") has no filename/line
-- to key off, so - like the old errorformat - it is not reported as a
-- separate quickfix entry; the frame line(s) above it already point at the
-- offending code.
local parselib = require('overseer.parselib')

local M = {}

-- A single traceback frame. Only the last such frame is normally the actual
-- source of the error, but we report every frame: this mirrors the old
-- errorformat behavior and lets you jump through the call chain via the
-- quickfix list.
M.parse_traceback_frame = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^%s*File "(.+)", line (%d+), in (.+)$'),
  { 'filename', 'lnum', 'text' }
)

M.new_parser = function()
  local diagnostics = {}
  return {
    parse = function(_, line)
      local item = M.parse_traceback_frame(line)
      if item then
        item.type = 'E'
        table.insert(diagnostics, item)
      end
    end,
    get_result = function()
      return { diagnostics = diagnostics }
    end,
    reset = function()
      diagnostics = {}
    end,
  }
end

return M
