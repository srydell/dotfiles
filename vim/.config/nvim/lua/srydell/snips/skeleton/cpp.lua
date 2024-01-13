local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local extras = require('luasnip.extras')
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

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
--   'DSF_UTIL_PERF_HISTOGRAM_HPP'
--
local function get_include_guard(project_info)
  local guard = { string.upper(project_info.name) }

  for j = 1, #project_info.path do
    local path = string.gsub(project_info.path[j], '%.', '_')
    table.insert(guard, string.upper(path))
  end

  return table.concat(guard, '_')
end

local function get_license()
  return [[/*
 * This file is subject to the terms and conditions defined in
 * file 'LICENSE.txt', which is part of this source code package.
 */
]]
end

local function basic_include_guard(project_info)
  local license = ''
  if project_info.name == 'dsf' then
    license = get_license()
  end

  local guard = get_include_guard(project_info)
  local snippet = string.format(
    [[#ifndef %s
#define %s
%s
namespace %s {
  <>
}

#endif // ifndef %s
    ]],
    guard,
    guard,
    license,
    util.get_namespace(project_info),
    guard
  )

  return s('_skeleton', fmta(snippet, { i(0) }))
end

local function dsf(project_info)
  local license = get_license()
  local snippet = string.format(
    [[%s
namespace %s {
  <>
}
      ]],
    license,
    util.get_namespace(project_info)
  )
  return s('_skeleton', fmta(snippet, { i(0) }))
end

local function prototype()
  return s(
    '_skeleton',
    fmta(
      [[
        #include <<iostream>>

        int main() {
          <>
        }
      ]],
      {
        i(0),
      }
    )
  )
end

local function leetcode()
  return s(
    '_skeleton',
    fmta(
      [[
        #include <<algorithm>>
        #include <<iostream>>
        #include <<limits>>
        #include <<map>>
        #include <<numeric>>
        #include <<queue>>
        #include <<set>>
        #include <<stack>>
        #include <<string>>
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
          Solution solution;

          {
            auto ans = solution.<>();
            std::cout <<<< "Got:      " <<<< ans <<<< '\n';
            std::cout <<<< "Expected: " <<<< 0 <<<< '\n';
            std::cout << "-------------------------------------" << '\n';
          }

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

local function pragma_once(_)
  return s(
    '_skeleton',
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

-- Dummy function for structure
local function no_op(_)
  return nil
end

-- Map over the snippets available
-- skel.ext.project
local skel = {
  hpp = {
    dsf = basic_include_guard,
    _fallback = pragma_once,
  },
  h = {
    _fallback = basic_include_guard,
  },
  cpp = {
    dsf = dsf,
    prototype = prototype,
    leetcode = leetcode,
    _fallback = no_op,
  },
}

local function skeleton()
  local ext = vim.fn.expand('%:e')
  if skel[ext] then
    local project = util.get_project()
    local name = project.name
    if name and skel[ext][name] then
      return skel[ext][name](project)
    end

    return skel[ext]._fallback(project)
  end

  return nil
end

return {
  snip = skeleton(),
}
