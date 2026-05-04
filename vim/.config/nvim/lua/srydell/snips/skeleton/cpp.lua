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

local function leetcode_fallback()
  return s(
    '_skeleton',
    fmta(
      [[
        #include <<iostream>>
        #include "helpers.hpp"

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
            std::cout <<<< "Input:    " <<<< 0 <<<< '\n';
            auto ans = solution.<>();
            std::cout <<<< "Got:      " <<<< ans <<<< '\n';
            std::cout <<<< "Expected: " <<<< 0 <<<< '\n';
            std::cout <<<< "-------------------------------------" <<<< '\n';
          }

        }
      ]],
      {
        i(1, 'int'),
        i(2, 'solve'),
        i(3),
        i(0),
        rep(2),
      }
    )
  )
end

local function fmta_escape(text)
  if type(text) ~= 'string' then
    return ''
  end

  return text:gsub('<', '<<'):gsub('>', '>>')
end

local function get_leetcode_problem_id()
  return vim.fn.expand('%:p'):match('/src/(%d+)%a*%.cpp$')
end

local function fetch_leetcode_problem()
  local problem_id = get_leetcode_problem_id()
  if not problem_id then
    return nil
  end

  local script = vim.fn.stdpath('config') .. '/tools/leetcode_fetch.py'
  local output = vim.fn.system({ 'python3', script, problem_id })
  if vim.v.shell_error ~= 0 or output == '' then
    return nil
  end

  local ok, problem = pcall(vim.json.decode, output)
  if not ok or type(problem) ~= 'table' then
    return nil
  end

  return problem
end

local function list_or_empty(value)
  if type(value) == 'table' then
    return value
  end
  return {}
end

local function is_nonempty_string(value)
  return type(value) == 'string' and value ~= ''
end

local function table_or_nil(value)
  if type(value) == 'table' then
    return value
  end
  return nil
end

local function string_or(value, default)
  if type(value) == 'string' then
    return value
  end
  return default
end

local function get_solution_params(problem)
  local params = {}
  for _, param in ipairs(list_or_empty(problem.signature.params)) do
    if type(param) == 'table' and is_nonempty_string(param.type) and is_nonempty_string(param.name) then
      table.insert(params, string.format('%s %s', param.type, param.name))
    end
  end
  return table.concat(params, ', ')
end

local function get_call_args(example)
  local args = {}
  for _, arg in ipairs(list_or_empty(example.arguments)) do
    if type(arg) == 'table' and is_nonempty_string(arg.name) then
      table.insert(args, arg.name)
    end
  end
  return table.concat(args, ', ')
end

local function get_answer_expression(return_type)
  if type(return_type) ~= 'string' then
    return 'ans'
  end

  if string.match(return_type or '', '^vector<') or return_type == 'ListNode*' or return_type == 'TreeNode*' then
    return 'str(ans)'
  end
  return 'ans'
end

local function get_print_expression(name, cxx_type)
  if type(cxx_type) ~= 'string' then
    return name
  end

  if string.match(cxx_type or '', '^vector<') or cxx_type == 'ListNode*' or cxx_type == 'TreeNode*' then
    return 'str(' .. name .. ')'
  end
  return name
end

local function get_input_expression(example)
  local parts = {}
  for _, arg in ipairs(list_or_empty(example.arguments)) do
    if type(arg) == 'table' and is_nonempty_string(arg.name) then
      table.insert(parts, get_print_expression(arg.name, arg.type))
    end
  end

  if #parts == 0 then
    return '""'
  end

  local expression = parts[1]
  for index = 2, #parts do
    expression = expression .. ' << ", " << ' .. parts[index]
  end
  return expression
end

local function wrap_comment_text(text, max_width)
  if type(text) ~= 'string' then
    return {}
  end

  local lines = {}
  local current = ''

  for word in string.gmatch(text or '', '%S+') do
    if current == '' then
      current = word
    elseif #current + #word + 1 <= max_width then
      current = current .. ' ' .. word
    else
      table.insert(lines, current)
      current = word
    end
  end

  if current ~= '' then
    table.insert(lines, current)
  end

  return lines
end

local function get_problem_header(problem)
  local lines = {}

  if is_nonempty_string(problem.title) then
    table.insert(lines, '// ' .. problem.title)
  end
  if is_nonempty_string(problem.difficulty) then
    table.insert(lines, '// Difficulty: ' .. problem.difficulty)
  end

  if #lines > 0 and is_nonempty_string(problem.description) then
    table.insert(lines, '//')
  end

  for _, line in ipairs(wrap_comment_text(problem.description, 88)) do
    table.insert(lines, '// ' .. line)
  end

  if #lines == 0 then
    return ''
  end

  return table.concat(lines, '\n') .. '\n\n'
end

local function add_explanation(lines, explanation)
  if not is_nonempty_string(explanation) then
    return
  end

  for line in string.gmatch(explanation, '[^\n]+') do
    table.insert(lines, '    // ' .. line)
  end
end

local function get_example_blocks(problem)
  local blocks = {}
  local return_type = string_or(problem.signature.return_type, 'int')

  for _, example in ipairs(list_or_empty(problem.examples)) do
    if type(example) ~= 'table' then
      goto continue
    end

    local lines = { '  {' }
    local expected = string_or(example.expected, '{}')

    add_explanation(lines, example.explanation)
    for _, arg in ipairs(list_or_empty(example.arguments)) do
      if type(arg) == 'table' and is_nonempty_string(arg.declaration) then
        table.insert(lines, '    ' .. arg.declaration)
      end
    end

    if return_type ~= 'void' then
      table.insert(lines, string.format('    %s expected = %s;', return_type, expected))
    end
    table.insert(lines, string.format([[    std::cout << "Input:    " << %s << '\n';]], get_input_expression(example)))
    if return_type == 'void' then
      table.insert(lines, string.format('    solution.%s(%s);', problem.signature.name, get_call_args(example)))
    else
      table.insert(
        lines,
        string.format('    auto ans = solution.%s(%s);', problem.signature.name, get_call_args(example))
      )
      table.insert(
        lines,
        string.format([[    std::cout << "Got:      " << %s << '\n';]], get_answer_expression(return_type))
      )
      table.insert(
        lines,
        string.format([[    std::cout << "Expected: " << %s << '\n';]], get_print_expression('expected', return_type))
      )
    end
    table.insert(lines, [[    std::cout << "-------------------------------------" << '\n';]])
    table.insert(lines, '  }')
    table.insert(blocks, table.concat(lines, '\n'))

    ::continue::
  end

  return table.concat(blocks, '\n\n')
end

local function leetcode()
  local problem = fetch_leetcode_problem()
  if not problem then
    return leetcode_fallback()
  end

  problem.signature = table_or_nil(problem.signature)
  if not problem.signature or not is_nonempty_string(problem.signature.name) then
    return leetcode_fallback()
  end

  local snippet = string.format(
    [[
%s#include <<iostream>>
#include "helpers.hpp"

using namespace std;
class Solution {
public:
  %s %s(%s) {
    <>
  }
};

int main() {
  Solution solution;

%s
}
]],
    fmta_escape(get_problem_header(problem)),
    fmta_escape(string_or(problem.signature.return_type, 'int')),
    problem.signature.name,
    fmta_escape(get_solution_params(problem)),
    fmta_escape(get_example_blocks(problem))
  )

  return s('_skeleton', fmta(snippet, { i(0) }))
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
