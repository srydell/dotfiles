local ls = require('luasnip')
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require('luasnip.util.events')
local ai = require('luasnip.nodes.absolute_indexer')
local extras = require('luasnip.extras')
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local conds = require('luasnip.extras.expand_conditions')
local postfix = require('luasnip.extras.postfix').postfix
local types = require('luasnip.util.types')
local parse = require('luasnip.util.parser').parse_snippet
local ms = ls.multi_snippet
local k = require('luasnip.nodes.key_indexer').new_key

local util = require('srydell.util')

-- Get a C-style include guard based on project information
--
-- E.g.
-- INPUT:
--   {
--     name = 'dsf',
--     path = { 'util', 'perf', 'histogram.hpp' }
--   }
-- OUTPUT:
--   'DSF_SRC_UTIL_PERF_HISTOGRAM_HPP'
--
local function get_include_guard(project_info)
  local guard = { string.upper(project_info.name) }

  for i=1,#project_info.path do
    local path = string.gsub(project_info.path[i], '%.', '_')
    table.insert(guard, string.upper(path))
  end

  return table.concat(guard, '_')
end

local function get_license()
  return
    [[/*
 * This file is subject to the terms and conditions defined in
 * file 'LICENSE.txt', which is part of this source code package.
 */
]]
end

local function get_namespace(project_info)
  return string.format(
  [[namespace %s {
  <>
}]], util.get_namespace(project_info))
end

local function get_c_style_include_guard(project_info)
  local license = ''
  if project_info.name == 'dsf' then
    license = get_license()
  end

  local guard = get_include_guard(project_info)
  local snippet = string.format(
    [[#ifndef %s
#define %s
%s
%s

#endif // ifndef %s
    ]], guard, guard, license, get_namespace(project_info), guard)

  return snippet
end

local function cpp_dsf(project_info)
    local license = get_license()
    local snippet = string.format(
      [[%s
%s
      ]], license, get_namespace(project_info))
    return s('_skeleton', fmta( snippet, { i(0) }))
end

local function cpp_prototype()
  return s('_skeleton',
    fmta(
      [[
        #include <<iostream>>

        int main() {
          <>
        }
      ]],
      {
        i(0)
      }
    )
  )
end

local function cpp_leetcode()
  return s('_skeleton',
    fmta(
      [[
        #include <<algorithm>>
        #include <<iostream>>
        #include <<map>>
        #include <<set>>
        #include <<unordered_map>>
        #include <<unordered_set>>
        #include <<vector>>

        using namespace std;

        class Solution {
          public:
              <> <>(<>) {
                <>
              }
        };

        int main() {
          Solution s;
          s.<>();
        }
      ]],
      {
        i(1, 'void'),
        i(2, 'solve'),
        i(3),
        i(0),
        rep(2),
      }
    )
  )
end

local function hpp()
  local project_info = util.get_project()
  if project_info.name and project_info.name == 'dsf' then
    return s('_skeleton', fmta( get_c_style_include_guard(project_info), { i(0) }))
  end

  -- Default to simple pragma once
  return s('_skeleton',
    fmta(
      [[
        #pragma once

        <>
      ]],
      {
        i(0),
      }
    )
  )
end

local function h()
  local project_info = util.get_project()
  if project_info.name then
    return s('_skeleton', fmta( get_c_style_include_guard(project_info), { i(0) }))
  end

  return nil
end

local function cpp()
  local project_info = util.get_project()
  vim.print(project_info)
  if project_info.name then
    if project_info.name == 'dsf' then
      return cpp_dsf(project_info)
    elseif project_info.name == 'prototype' then
      return cpp_prototype()
    elseif project_info.name == 'leetcode' then
      return cpp_leetcode()
    end
  end

  return nil
end

local function skeleton()
  local extension = vim.fn.expand('%:e')
  if extension == 'hpp' then
    return hpp()
  elseif extension == 'h' then
    return h()
  elseif extension == 'cpp' then
    return cpp()
  end

  return nil
end

return {
  snip = skeleton()
}
