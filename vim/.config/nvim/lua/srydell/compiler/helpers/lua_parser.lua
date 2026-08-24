-- Pure-Lua replacement for lua.lua's old vim-errorformat-based parsing.
-- Built on overseer.parselib (see cpp_parser.lua for the pattern this
-- follows). The reference `lua` interpreter reports uncaught errors as:
--   lua: /tmp/luatest.lua:2: boom
local parselib = require('overseer.parselib')

local M = {}

M.parse_diagnostic =
  parselib.make_parse_fn(parselib.make_lua_match_fn('^lua: ([^:%s]+):(%d+): (.+)$'), { 'filename', 'lnum', 'text' })

M.new_parser = function()
  local diagnostics = {}
  return {
    parse = function(_, line)
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
