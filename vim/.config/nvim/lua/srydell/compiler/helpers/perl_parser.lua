-- Pure-Lua replacement for perl.lua's old vim-errorformat-based parsing.
-- Built on overseer.parselib (see cpp_parser.lua for the pattern this
-- follows). Perl errors/warnings/die messages share one common shape:
--   <message> at <file> line <lnum>.
--   <message> at <file> line <lnum>, near "..."
local parselib = require('overseer.parselib')

local M = {}

-- e.g. "syntax error at perltest.pl line 3, near "= ;""
--      "custom error at perlok.pl line 2."
M.parse_diagnostic = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^(.+) at (%S+) line (%d+)[.,]'),
  { 'text', 'filename', 'lnum' }
)

-- perl prints this summary line after a failed compile; it repeats
-- information already reported by the "at FILE line N" diagnostics above,
-- so treat it as noise rather than a second, filename-less quickfix entry.
M.is_suppressed_noise = parselib.make_lua_test_fn('^Execution of %S+ aborted due to compilation errors%.$')

M.new_parser = function()
  local diagnostics = {}
  return {
    parse = function(_, line)
      if M.is_suppressed_noise(line) then
        return
      end
      local item = M.parse_diagnostic(line)
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
