local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local extras = require('luasnip.extras')
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

local util = require('srydell.util')

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

  local guard = util.get_include_guard(project_info)
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

local function get_test_name(filename)
  -- Assume filename is on form 'test_blahblah.cpp'
  filename = string.sub(filename, 6)
  -- Now 'blahblah.cpp'
  filename = string.sub(filename, 1, #filename - 4)
  -- Now 'blahblah'
  return filename
end

local function get_test_include_path(project_info, test_name)
  local index = util.index_of(project_info.path, 'test')
  if not index then
    index = #project_info.path
  end
  index = index - 1

  -- util/round.h
  local include_path = table.concat(project_info.path, '/', 1, index) .. '/' .. test_name .. '.h'
  return include_path
end

local function dsf_test(project_info, filename)
  local license = get_license()
  local test_name = get_test_name(filename)
  local include_path = get_test_include_path(project_info, test_name)
  local snippet = string.format(
    [[%s
#include "%s"

#include <<boost/test/data/test_case.hpp>>
#include <<boost/test/unit_test.hpp>>

BOOST_AUTO_TEST_SUITE(%s)

BOOST_AUTO_TEST_CASE(<>)
{
  <>
}

BOOST_AUTO_TEST_SUITE_END()
      ]],
    license,
    include_path,
    test_name
  )
  return s('_skeleton', fmta(snippet, { i(1), i(0) }))
end

local function dsf_cpp(project_info)
  local filename = project_info.path[#project_info.path]
  if string.match(filename, 'test_') then
    return dsf_test(project_info, filename)
  end

  local include = ''
  local cpp_util = require('srydell.util.cpp')
  local header = cpp_util.get_alternative_include_guess()
  if header ~= '' then
    include = string.format(
      [[

#include "%s"
]],
      header
    )
  end

  local license = get_license()
  local snippet = string.format(
    [[%s%s
namespace %s {
  <>
}
      ]],
    license,
    include,
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



        class Solution {
        public:
          <> <>(<>) {
            <>
          }
        };

        int main() {
          Solution solution;

          {
            std::cout <<<< "Input:    " <<<< 0 <<<< '\n';
            auto ans = solution.<>();
            std::cout <<<< "Got:      " <<<< ans <<<< '\n';
            std::cout <<<< "Expected: " <<<< 0 <<<< '\n';
            std::cout <<<< "-------------------------------------" <<<< '\n';
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
    dsf = dsf_cpp,
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
