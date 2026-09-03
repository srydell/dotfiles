-- Pure-Lua replacement for python.lua's old vim-errorformat-based parsing.
-- Built on overseer.parselib (see cpp_parser.lua for the pattern this
-- follows). Handles both CPython traceback frame shapes:
--   File "/private/tmp/pytest.py", line 3, in <module>
--   File "/private/tmp/syntax_err.py", line 1
-- The second (no ", in ...") shape is what SyntaxError/IndentationError
-- produce, since they fail before any function context exists to name.
-- The exception line itself (e.g. "ValueError: boom") has no filename/line
-- to key off, so it is not reported as a separate quickfix entry. Instead,
-- its message is appended to the last frame's text, since that message is
-- often the only part of the traceback that says *why* it failed (e.g.
-- "ModuleNotFoundError: No module named 'dgrammar'" vs. just "<module>").
local parselib = require('overseer.parselib')

local M = {}

-- A single traceback frame, with function context (the common case for
-- runtime exceptions -- ValueError, AssertionError, etc.).
local parse_frame_with_context = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^%s*File "(.+)", line (%d+), in (.+)$'),
  { 'filename', 'lnum', 'text' }
)

-- The same frame shape without function context, as produced by
-- SyntaxError/IndentationError (there's no enclosing function to name when
-- parsing fails before execution starts).
local parse_frame_without_context =
  parselib.make_parse_fn(parselib.make_lua_match_fn('^%s*File "(.+)", line (%d+)$'), { 'filename', 'lnum' })

-- Only the last such frame is normally the actual source of the error, but
-- we report every frame: this mirrors the old errorformat behavior and lets
-- you jump through the call chain via the quickfix list.
M.parse_traceback_frame = function(line)
  return parse_frame_with_context(line) or parse_frame_without_context(line)
end

-- The final line of a traceback: an unindented "ExceptionName: message"
-- (e.g. "ModuleNotFoundError: No module named 'dgrammar'"). Requires a
-- message so it doesn't misfire on unrelated unindented lines.
local parse_exception_line = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^([%w_.]+): (.+)$'),
  { 'name', 'message' }
)

M.new_parser = function()
  local diagnostics = {}
  return {
    parse = function(_, line)
      local frame = M.parse_traceback_frame(line)
      if frame then
        frame.type = 'E'
        table.insert(diagnostics, frame)
        return
      end
      local exception = parse_exception_line(line)
      if exception and #diagnostics > 0 then
        local last = diagnostics[#diagnostics]
        last.text = string.format('%s: %s: %s', last.text, exception.name, exception.message)
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
