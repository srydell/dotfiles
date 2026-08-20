-- Public entry point for all C++ treesitter tooling used by snippets,
-- ftplugin/cpp.lua keymaps, and autocmds/cpp.lua.
--
-- The implementation lives in focused submodules grouped by concern:
--   navigation.lua               - generic, language-agnostic tree-walking
--   cpp/predicates.lua            - cpp node-type predicates
--   cpp/class_info.lua            - class/struct lookups + indentation
--   cpp/function_signature.lua    - signature text extraction (internal)
--   cpp/atomics.lua                - "make atomic" refactors
--   cpp/enums.lua                  - enum code generators
--   cpp/includes.lua               - #include management
--   cpp/class_members.lua          - rule-of-5 deleted move/copy members
--   cpp/definitions.lua            - constructor/destructor definers
--   cpp/struct_layout.lua           - qualified name lookup for struct-layout inspection
--
-- This file requires them and merges their public tables into one, so
-- `require('srydell.treesitter.cpp')` exposes a single flat API.
local navigation = require('srydell.treesitter.navigation')
local predicates = require('srydell.treesitter.cpp.predicates')
local class_info = require('srydell.treesitter.cpp.class_info')
local atomics = require('srydell.treesitter.cpp.atomics')
local enums = require('srydell.treesitter.cpp.enums')
local includes = require('srydell.treesitter.cpp.includes')
local class_members = require('srydell.treesitter.cpp.class_members')
local definitions = require('srydell.treesitter.cpp.definitions')
local struct_layout = require('srydell.treesitter.cpp.struct_layout')

local M = {}

for _, module in ipairs({
  navigation,
  predicates,
  class_info,
  atomics,
  enums,
  includes,
  class_members,
  definitions,
  struct_layout,
}) do
  for key, value in pairs(module) do
    M[key] = value
  end
end

return M
