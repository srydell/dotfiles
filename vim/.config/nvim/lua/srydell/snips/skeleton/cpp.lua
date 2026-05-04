-- C++ skeleton generators for project files, prototypes, and LeetCode solutions.
local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local extras = require('luasnip.extras')
local rep = extras.rep
local fmta = require('luasnip.extras.fmt').fmta

local util = require('srydell.util')

-- Return the license header used by DSF-generated files.
local function get_license()
  return [[/*
 * This file is subject to the terms and conditions defined in
 * file 'LICENSE.txt', which is part of this source code package.
 */
]]
end

-- Build a header skeleton with an include guard and project namespace.
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

-- Derive the tested unit name from a DSF test filename.
local function get_test_name(filename)
  -- Assume filename is on form 'test_blahblah.cpp'
  filename = string.sub(filename, 6)
  -- Now 'blahblah.cpp'
  filename = string.sub(filename, 1, #filename - 4)
  -- Now 'blahblah'
  return filename
end

-- Guess the production header included by a DSF test file.
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

-- Build the Boost.Test skeleton used by DSF test files.
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

-- Build a DSF source skeleton, or route test files to the test skeleton.
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

-- Build a minimal C++ main file for quick prototype projects.
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

-- Build an editable fallback when LeetCode metadata cannot be fetched.
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

-- Escape LuaSnip fmt markers that may appear in generated C++ text.
local function fmta_escape(text)
  if type(text) ~= 'string' then
    return ''
  end

  return text:gsub('<', '<<'):gsub('>', '>>')
end

-- Extract the numeric LeetCode ID from paths like leetcode/src/123.cpp.
local function get_leetcode_problem_id()
  return vim.fn.expand('%:p'):match('/src/(%d+)%a*%.cpp$')
end

-- Fetch and decode the compact JSON payload for the current LeetCode file.
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

-- Treat JSON null userdata and other non-lists as an empty list.
local function list_or_empty(value)
  if type(value) == 'table' then
    return value
  end
  return {}
end

-- Check for real strings; vim.NIL from JSON null is userdata and truthy.
local function is_nonempty_string(value)
  return type(value) == 'string' and value ~= ''
end

-- Return tables only when decoded JSON actually produced a table.
local function table_or_nil(value)
  if type(value) == 'table' then
    return value
  end
  return nil
end

-- Use a default when a decoded JSON value is missing or not a string.
local function string_or(value, default)
  if type(value) == 'string' then
    return value
  end
  return default
end

-- Render the C++ parameter list for a normal Solution method.
local function get_solution_params(problem)
  local params = {}
  for _, param in ipairs(list_or_empty(problem.signature.params)) do
    if type(param) == 'table' and is_nonempty_string(param.type) and is_nonempty_string(param.name) then
      table.insert(params, string.format('%s %s', param.type, param.name))
    end
  end
  return table.concat(params, ', ')
end

-- Render the argument names used in a normal Solution method call.
local function get_call_args(example)
  local args = {}
  for _, arg in ipairs(list_or_empty(example.arguments)) do
    if type(arg) == 'table' and is_nonempty_string(arg.name) then
      table.insert(args, arg.name)
    end
  end
  return table.concat(args, ', ')
end

-- Pick how to print a returned answer in the generated harness.
local function get_answer_expression(return_type)
  if type(return_type) ~= 'string' then
    return 'ans'
  end

  if string.match(return_type or '', '^vector<') or return_type == 'ListNode*' or return_type == 'TreeNode*' then
    return 'str(ans)'
  end
  return 'ans'
end

-- Pick how to print any named value based on its C++ type.
local function get_print_expression(name, cxx_type)
  if type(cxx_type) ~= 'string' then
    return name
  end

  if string.match(cxx_type or '', '^vector<') or cxx_type == 'ListNode*' or cxx_type == 'TreeNode*' then
    return 'str(' .. name .. ')'
  end
  return name
end

-- Build the "Input:" stream expression for one regular example.
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

-- Wrap long problem descriptions into readable C++ comment lines.
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

-- Render title, difficulty, and statement text at the top of the file.
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

-- Forward declaration because both LeetCode renderers share explanation output.
local add_explanation

-- Render constructor or method parameters for class-design problems.
local function get_design_param_list(params)
  local result = {}
  for _, param in ipairs(list_or_empty(params)) do
    if type(param) == 'table' and is_nonempty_string(param.type) and is_nonempty_string(param.name) then
      table.insert(result, string.format('%s %s', param.type, param.name))
    end
  end
  return table.concat(result, ', ')
end

-- Render raw argument values for class-design calls and log labels.
local function get_design_arg_values(arguments)
  local result = {}
  for _, argument in ipairs(list_or_empty(arguments)) do
    if type(argument) == 'table' and is_nonempty_string(argument.value) then
      table.insert(result, argument.value)
    end
  end
  return table.concat(result, ', ')
end

-- Render method stubs inside a LeetCode class-design skeleton.
local function get_design_method_blocks(design)
  local blocks = {}
  for _, method in ipairs(list_or_empty(design.methods)) do
    if type(method) == 'table' and is_nonempty_string(method.name) then
      local return_type = string_or(method.return_type, 'void')
      local lines = {
        string.format('  %s %s(%s) {', return_type, method.name, get_design_param_list(method.params)),
      }
      if return_type ~= 'void' then
        table.insert(lines, '    return {};')
      end
      table.insert(lines, '  }')
      table.insert(blocks, table.concat(lines, '\n'))
    end
  end
  return table.concat(blocks, '\n\n')
end

-- Render the editable constructor stub for a class-design problem.
local function get_design_constructor_block(design)
  return string.format(
    '  %s(%s) {\n    <>\n  }',
    design.class_name,
    fmta_escape(get_design_param_list(design.constructor and design.constructor.params))
  )
end

-- Render one class-design constructor or method call.
local function get_design_step_call(object_name, step)
  if step.constructor then
    return string.format('%s %s{%s};', step.operation, object_name, get_design_arg_values(step.arguments))
  end
  return string.format('%s.%s(%s)', object_name, step.operation, get_design_arg_values(step.arguments))
end

-- Render a human-readable operation label for class-design logging.
local function get_design_step_label(step)
  return string.format('%s(%s)', step.operation, get_design_arg_values(step.arguments))
end

-- Quote a log label safely for generated C++ string literals.
local function cpp_string_literal(text)
  text = string_or(text, '')
  text = text:gsub('\\', '\\\\'):gsub('"', '\\"')
  return '"' .. text .. '"'
end

-- Append the generated C++ lines for one class-design test step.
local function add_design_step_lines(lines, step, step_index)
  if type(step) ~= 'table' or not is_nonempty_string(step.operation) then
    return
  end

  table.insert(
    lines,
    string.format(
      [[    std::cout << %s << '\n';]],
      cpp_string_literal('Step ' .. step_index .. ': ' .. get_design_step_label(step))
    )
  )

  if step.constructor then
    table.insert(lines, '    ' .. get_design_step_call('obj', step))
    return
  end

  local return_type = string_or(step.return_type, 'void')
  if return_type == 'void' then
    table.insert(lines, '    ' .. get_design_step_call('obj', step) .. ';')
    return
  end

  local ans_name = 'ans' .. tostring(step_index)
  table.insert(lines, string.format('    auto %s = %s;', ans_name, get_design_step_call('obj', step)))
  table.insert(
    lines,
    string.format([[    std::cout << "Got:      " << %s << '\n';]], get_print_expression(ans_name, return_type))
  )
  if is_nonempty_string(step.expected) then
    table.insert(lines, string.format([[    std::cout << "Expected: " << %s << '\n';]], step.expected))
  end
end

-- Render all examples for a LeetCode class-design harness.
local function get_design_example_blocks(design)
  local blocks = {}
  for example_index, example in ipairs(list_or_empty(design.examples)) do
    if type(example) ~= 'table' then
      goto continue
    end

    local lines = { '  {' }
    table.insert(lines, string.format([[    std::cout << "Example %d" << '\n';]], example_index))
    add_explanation(lines, example.explanation)

    for step_index, step in ipairs(list_or_empty(example.steps)) do
      add_design_step_lines(lines, step, step_index)
    end

    table.insert(lines, [[    std::cout << "-------------------------------------" << '\n';]])
    table.insert(lines, '  }')
    table.insert(blocks, table.concat(lines, '\n'))

    ::continue::
  end
  return table.concat(blocks, '\n\n')
end

-- Decide whether the fetched payload describes a class-design problem.
local function is_design_problem(problem)
  return type(problem.design) == 'table' and is_nonempty_string(problem.design.class_name)
end

-- Build the dedicated skeleton for LeetCode class-design problems.
local function leetcode_design(problem)
  local design = problem.design
  local snippet = string.format(
    [[
%s#include <<iostream>>
#include "helpers.hpp"

using namespace std;
class %s {
public:
%s

%s
};

int main() {
%s
}
]],
    fmta_escape(get_problem_header(problem)),
    design.class_name,
    get_design_constructor_block(design),
    fmta_escape(get_design_method_blocks(design)),
    fmta_escape(get_design_example_blocks(design))
  )

  return s('_skeleton', fmta(snippet, { i(0) }))
end

-- Add LeetCode example explanations as comments above a test block.
function add_explanation(lines, explanation)
  if not is_nonempty_string(explanation) then
    return
  end

  for line in string.gmatch(explanation, '[^\n]+') do
    table.insert(lines, '    // ' .. line)
  end
end

-- Render all regular LeetCode examples into runnable C++ blocks.
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

-- Build a LeetCode skeleton, choosing class-design or normal Solution mode.
local function leetcode()
  local problem = fetch_leetcode_problem()
  if not problem then
    return leetcode_fallback()
  end

  if is_design_problem(problem) then
    return leetcode_design(problem)
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

-- Build a generic header skeleton for non-DSF headers.
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

-- Return no skeleton for C++ files that do not have a known project template.
local function no_op(_)
  return nil
end

-- Map file extension and project name to the skeleton generator.
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

-- Pick the skeleton generator for the current file.
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
