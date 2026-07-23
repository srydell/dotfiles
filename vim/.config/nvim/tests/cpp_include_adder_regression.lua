-- Run with:
-- $ nvim --headless -u init.lua -l tests/cpp_include_adder_regression.lua
--
-- This suite intentionally uses many small, named cases. Include inference is
-- conservative and syntax-sensitive; a broad matrix makes it much easier to
-- identify exactly which lookup, scope, or placement rule regressed.
local ts_cpp = require('srydell.treesitter.cpp')

local function set_lines(lines)
  vim.cmd('enew!')
  vim.bo.filetype = 'cpp'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function assert_lines(case)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(
    vim.deep_equal(actual, case.expected),
    string.format(
      '%s failed\nexpected:\n%s\nactual:\n%s',
      case.name,
      table.concat(case.expected, '\n'),
      table.concat(actual, '\n')
    )
  )
end

local function run(case)
  set_lines(case.input)
  ts_cpp.include_necessary_types(case.user_includes)
  assert_lines(case)
end

local cases = {
  {
    name = 'qualified type',
    input = { 'std::string value;' },
    expected = { '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'multiple qualified types are deterministic',
    input = { 'std::vector<int> values;', 'std::map<int, int> lookup;', 'std::optional<int> result;' },
    expected = {
      '#include <map>',
      '#include <optional>',
      '#include <vector>',
      '',
      'std::vector<int> values;',
      'std::map<int, int> lookup;',
      'std::optional<int> result;',
    },
  },
  {
    name = 'qualified nested template types',
    input = { 'std::vector<std::string> values;' },
    expected = { '#include <string>', '#include <vector>', '', 'std::vector<std::string> values;' },
  },
  {
    name = 'deep qualified type',
    input = { 'std::chrono::duration<int> elapsed;' },
    expected = { '#include <chrono>', '', 'std::chrono::duration<int> elapsed;' },
  },
  {
    name = 'qualified function calls',
    input = { 'std::sort(first, last);', 'std::exchange(value, next);' },
    expected = {
      '#include <algorithm>',
      '#include <utility>',
      '',
      'std::sort(first, last);',
      'std::exchange(value, next);',
    },
  },
  {
    name = 'qualified allocation helper',
    input = { 'auto value = std::make_unique<int>(1);' },
    expected = { '#include <memory>', '', 'auto value = std::make_unique<int>(1);' },
  },
  {
    name = 'existing header suppresses duplicate',
    input = { '#include <vector>', '', 'std::vector<int> values;' },
    expected = { '#include <vector>', '', 'std::vector<int> values;' },
  },
  {
    name = 'only missing header is inserted',
    input = { '#include <vector>', '', 'std::vector<std::string> values;' },
    expected = { '#include <string>', '#include <vector>', '', 'std::vector<std::string> values;' },
  },
  {
    name = 'transitively supplied initializer list is skipped',
    input = { 'std::vector<int> values;', 'std::initializer_list<int> source;' },
    expected = {
      '#include <vector>',
      '',
      'std::vector<int> values;',
      'std::initializer_list<int> source;',
    },
  },
  {
    name = 'initializer list is included when used alone',
    input = { 'std::initializer_list<int> source;' },
    expected = { '#include <initializer_list>', '', 'std::initializer_list<int> source;' },
  },
  {
    name = 'custom qualified mapping',
    input = { 'project::Widget widget;' },
    user_includes = { ['project::Widget'] = '"project/widget.hpp"' },
    expected = { '#include "project/widget.hpp"', '', 'project::Widget widget;' },
  },
  {
    name = 'custom function mapping',
    input = { 'project::make_widget();' },
    user_includes = { ['project::make_widget'] = '"project/widget.hpp"' },
    expected = { '#include "project/widget.hpp"', '', 'project::make_widget();' },
  },
  {
    name = 'unknown qualified symbol is ignored',
    input = { 'unknown::Thing value;' },
    expected = { 'unknown::Thing value;' },
  },
  {
    name = 'namespace import resolves type',
    input = { 'using namespace std;', 'vector<int> values;' },
    expected = { '#include <vector>', '', 'using namespace std;', 'vector<int> values;' },
  },
  {
    name = 'namespace import resolves several types',
    input = { 'using namespace std;', 'string text;', 'optional<int> value;', 'map<int, int> lookup;' },
    expected = {
      '#include <map>',
      '#include <optional>',
      '#include <string>',
      '',
      'using namespace std;',
      'string text;',
      'optional<int> value;',
      'map<int, int> lookup;',
    },
  },
  {
    name = 'namespace import resolves nested unqualified templates',
    input = { 'using namespace std;', 'vector<string> values;' },
    expected = {
      '#include <string>',
      '#include <vector>',
      '',
      'using namespace std;',
      'vector<string> values;',
    },
  },
  {
    name = 'namespace import resolves function',
    input = { 'using namespace std;', 'exchange(value, next);' },
    expected = { '#include <utility>', '', 'using namespace std;', 'exchange(value, next);' },
  },
  {
    name = 'explicit symbol import resolves type',
    input = { 'using std::optional;', 'optional<int> value;' },
    expected = { '#include <optional>', '', 'using std::optional;', 'optional<int> value;' },
  },
  {
    name = 'explicit symbol import itself requires its declaration',
    input = { 'using std::string;' },
    expected = { '#include <string>', '', 'using std::string;' },
  },
  {
    name = 'namespace import does not apply before declaration',
    input = { 'vector<int> before;', 'using namespace std;' },
    expected = { 'vector<int> before;', 'using namespace std;' },
  },
  {
    name = 'outer namespace import applies in compound statement',
    input = { 'using namespace std;', 'void f() {', '  vector<int> values;', '}' },
    expected = {
      '#include <vector>',
      '',
      'using namespace std;',
      'void f() {',
      '  vector<int> values;',
      '}',
    },
  },
  {
    name = 'compound import does not escape its scope',
    input = { 'void f() {', '  using namespace std;', '}', 'vector<int> outside;' },
    expected = { 'void f() {', '  using namespace std;', '}', 'vector<int> outside;' },
  },
  {
    name = 'compound import applies to nested compound scope',
    input = {
      'void f() {',
      '  using namespace std;',
      '  if (condition) {',
      '    vector<int> values;',
      '  }',
      '}',
    },
    expected = {
      '#include <vector>',
      '',
      'void f() {',
      '  using namespace std;',
      '  if (condition) {',
      '    vector<int> values;',
      '  }',
      '}',
    },
  },
  {
    name = 'sibling compound scope cannot see import',
    input = {
      'void first() {',
      '  using namespace std;',
      '}',
      'void second() {',
      '  vector<int> values;',
      '}',
    },
    expected = {
      'void first() {',
      '  using namespace std;',
      '}',
      'void second() {',
      '  vector<int> values;',
      '}',
    },
  },
  {
    name = 'one known imported namespace resolves candidate',
    input = { 'using namespace known;', 'using namespace unknown;', 'Thing value;' },
    user_includes = { ['known::Thing'] = '"known/thing.hpp"' },
    expected = {
      '#include "known/thing.hpp"',
      '',
      'using namespace known;',
      'using namespace unknown;',
      'Thing value;',
    },
  },
  {
    name = 'two known imported namespaces are ambiguous',
    input = { 'using namespace first;', 'using namespace second;', 'Thing value;' },
    user_includes = {
      ['first::Thing'] = '"first/thing.hpp"',
      ['second::Thing'] = '"second/thing.hpp"',
    },
    expected = { 'using namespace first;', 'using namespace second;', 'Thing value;' },
  },
  {
    name = 'ambiguity remains even when headers happen to match',
    input = { 'using namespace first;', 'using namespace second;', 'Thing value;' },
    user_includes = {
      ['first::Thing'] = '"shared/thing.hpp"',
      ['second::Thing'] = '"shared/thing.hpp"',
    },
    expected = { 'using namespace first;', 'using namespace second;', 'Thing value;' },
  },
  {
    name = 'member function call is ignored',
    input = { 'using namespace std;', 'object.move();' },
    expected = { 'using namespace std;', 'object.move();' },
  },
  {
    name = 'member function through pointer is ignored',
    input = { 'using namespace std;', 'object->exchange();' },
    expected = { 'using namespace std;', 'object->exchange();' },
  },
  {
    name = 'bare variable name is not treated as function',
    input = { 'using namespace std;', 'int move = 0;' },
    expected = { 'using namespace std;', 'int move = 0;' },
  },
  {
    name = 'comment text is ignored',
    input = { 'using namespace std;', '// vector<string> and move(value)' },
    expected = { 'using namespace std;', '// vector<string> and move(value)' },
  },
  {
    name = 'string literal text is ignored',
    input = { 'using namespace std;', 'const char* text = "vector<string>";' },
    expected = { 'using namespace std;', 'const char* text = "vector<string>";' },
  },
  {
    name = 'empty file remains unchanged',
    input = {},
    expected = { '' },
  },
  {
    name = 'line comment preamble is preserved',
    input = { '// Copyright', '// License', '', 'std::string value;' },
    expected = { '// Copyright', '// License', '', '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'single-line block comment preamble is preserved',
    input = { '/* Copyright */', '', 'std::string value;' },
    expected = { '/* Copyright */', '', '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'multiline block comment preamble is preserved',
    input = { '/*', ' * Copyright', ' */', '', 'std::string value;' },
    expected = { '/*', ' * Copyright', ' */', '', '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'pragma once without blank remains first',
    input = { '#pragma once', 'std::string value;' },
    expected = { '#pragma once', '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'spaced pragma once is recognized',
    input = { '# pragma once', '', 'std::string value;' },
    expected = { '# pragma once', '', '#include <string>', '', 'std::string value;' },
  },
  {
    name = 'include guard without blank contains include',
    input = { '#ifndef VALUE_HPP', '#define VALUE_HPP', 'std::string value;', '#endif' },
    expected = {
      '#ifndef VALUE_HPP',
      '#define VALUE_HPP',
      '#include <string>',
      '',
      'std::string value;',
      '#endif',
    },
  },
  {
    name = 'spaced include guard is recognized',
    input = { '# ifndef VALUE_HPP', '# define VALUE_HPP', '', 'std::string value;', '# endif' },
    expected = {
      '# ifndef VALUE_HPP',
      '# define VALUE_HPP',
      '',
      '#include <string>',
      '',
      'std::string value;',
      '# endif',
    },
  },
  {
    name = 'mismatched guard is not treated as include guard',
    input = { '#ifndef FIRST_HPP', '#define SECOND_HPP', 'std::string value;', '#endif' },
    expected = {
      '#include <string>',
      '',
      '#ifndef FIRST_HPP',
      '#define SECOND_HPP',
      'std::string value;',
      '#endif',
    },
  },
  {
    name = 'conditional duplicate does not satisfy dependency',
    input = { '#if FEATURE', '#include <string>', '#endif', 'std::string value;' },
    expected = {
      '#include <string>',
      '',
      '#if FEATURE',
      '#include <string>',
      '#endif',
      'std::string value;',
    },
  },
  {
    name = 'nested conditional duplicate does not satisfy dependency',
    input = {
      '#if FIRST',
      '#if SECOND',
      '#include <vector>',
      '#endif',
      '#endif',
      'std::vector<int> values;',
    },
    expected = {
      '#include <vector>',
      '',
      '#if FIRST',
      '#if SECOND',
      '#include <vector>',
      '#endif',
      '#endif',
      'std::vector<int> values;',
    },
  },
  {
    name = 'top-level spaced include suppresses duplicate',
    input = { '# include <string>', '', 'std::string value;' },
    expected = { '# include <string>', '', 'std::string value;' },
  },
  {
    name = 'blank lines containing spaces are preamble whitespace',
    input = { '// Copyright', '   ', 'std::string value;' },
    expected = { '// Copyright', '   ', '#include <string>', '', 'std::string value;' },
  },
}

for _, case in ipairs(cases) do
  run(case)
end

print(string.format('cpp_include_adder_regression: ok (%d cases)', #cases))
