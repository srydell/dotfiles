-- Pure-Lua replacement for cmake_configure.lua's vim-errorformat-based
-- parsing. Built on overseer.parselib (see cpp_parser.lua for the pattern
-- this follows).
--
-- This only covers CMake's own configure-time diagnostics, e.g.:
--   CMake Error at CMakeLists.txt:10 (message):
--   CMake Warning (dev) at src/CMakeLists.txt:5 (find_package):
-- The actual C++ *build* step (cmake_build.lua) invokes the underlying
-- generator (ninja/make), which emits clang/gcc-shaped diagnostics -- reuse
-- srydell.compiler.helpers.cpp_parser for that instead of this module, to
-- keep "CMake complained about my CMakeLists.txt" separate from "clang/gcc
-- complained about my C++ source".
local parselib = require('overseer.parselib')

local M = {}

-- The parenthesized "(dev)"/"(dev, unset)" annotation on warnings and the
-- trailing "(command_name)" context are both optional/variable text we don't
-- need to key on, so they're consumed loosely rather than captured.
M.parse_diagnostic = parselib.make_parse_fn(
  parselib.make_lua_match_fn('^CMake (%a+)[^:]- at ([^:]+):(%d+) %(.-%):$'),
  { 'type', 'filename', 'lnum' }
)

M.new_parser = function()
  local diagnostics = {}
  return {
    parse = function(_, line)
      local item = M.parse_diagnostic(line)
      if item then
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
