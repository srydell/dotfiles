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

local function get_project()
  return util.get_project_info(util.split(vim.fn.expand('%:p'), '/'))
end

local function get_license()
  return
    [[/*
      * This file is subject to the terms and conditions defined in
      * file 'LICENSE.txt', which is part of this source code package.
      */
    ]]
end

local function get_c_style_include_guard(project_info)
  local license = ''
  if project_info.name == 'dsf' then
    license = get_license()
  end

  local guard = get_include_guard(project_info)
  local snippet = string.format(
    [[
      #ifndef %s
      #define %s
      %s
      namespace %s {
        <>
      }

      #endif // ifndef %s
    ]], guard, guard, license, util.get_namespace(project_info), guard)

  return snippet
end

local function hpp()
  local project_info = get_project()
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
  local project_info = get_project()
  if project_info.name then
    return s('_skeleton', fmta( get_c_style_include_guard(project_info), { i(0) }))
  end

  return nil
end

local function cpp()
  -- local project_info = get_project()
  -- if project_info.name then
  -- end

  -- Check for 'prototype' in the parent directories
  if string.match(vim.fn.expand('%:p'), 'prototype') then
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
