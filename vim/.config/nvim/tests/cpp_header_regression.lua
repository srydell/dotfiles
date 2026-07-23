-- Run with
-- $ nvim --headless -u init.lua -l tests/cpp_header_regression.lua
local ts_cpp = require('srydell.treesitter.cpp')

local function assert_lines(expected)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(
    vim.deep_equal(actual, expected),
    string.format('expected:\n%s\nactual:\n%s', table.concat(expected, '\n'), table.concat(actual, '\n'))
  )
end

local function set_lines(lines)
  vim.cmd('enew!')
  vim.bo.filetype = 'cpp'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function include_necessary_types(user_includes)
  ts_cpp.include_necessary_types(user_includes)
  -- Reparse after buffer edits so a following operation observes the same
  -- state that the BufWritePre callback would see.
  vim.treesitter.get_parser(0, 'cpp'):parse()
end

set_lines({
  '#include <string>',
  '#include <vector>',
  '#include "align_int8.h"',
  '',
  'std::vector<int> xs;',
  'std::string s;',
})
ts_cpp.divide_and_sort_includes()
assert_lines({
  '#include <string>',
  '#include <vector>',
  '#include "align_int8.h"',
  '',
  'std::vector<int> xs;',
  'std::string s;',
})

set_lines({
  '#include <vector> // Public API exposes std::vector',
  '#include <string> /* Kept with string */',
  '',
  'std::vector<std::string> values;',
})
ts_cpp.divide_and_sort_includes()
assert_lines({
  '#include <string> /* Kept with string */',
  '#include <vector> // Public API exposes std::vector',
  '',
  'std::vector<std::string> values;',
})

vim.cmd('enew!')
vim.api.nvim_buf_set_name(0, '/tmp/proj/include/foo.h')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '#if FEATURE',
  '#define SOME_MACRO',
  '#endif',
  '',
  'class A {};',
})
ts_cpp.correct_include_guard()
assert_lines({
  '#if FEATURE',
  '#define SOME_MACRO',
  '#endif',
  '',
  'class A {};',
})

vim.cmd('enew!')
vim.api.nvim_buf_set_name(0, '/tmp/proj/include/foo.hpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '#ifndef OLD_GUARD',
  '#define OLD_GUARD',
  '',
  'class A {};',
  '',
  '#endif',
})
ts_cpp.correct_include_guard()
assert_lines({
  '#ifndef PROJ_FOO_HPP',
  '#define PROJ_FOO_HPP',
  '',
  'class A {};',
  '',
  '#endif',
})

vim.cmd('enew!')
vim.api.nvim_buf_set_name(0, '/tmp/my-project/include/detail/foo-bar.hpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '/*',
  ' * Copyright notice',
  ' */',
  '',
  '# ifndef OLD_GUARD',
  '',
  '// The define is intentionally separated from ifndef.',
  '# define OLD_GUARD // public header',
  '',
  'class A {};',
  '',
  '# endif // OLD_GUARD',
})
ts_cpp.correct_include_guard()
assert_lines({
  '/*',
  ' * Copyright notice',
  ' */',
  '',
  '# ifndef MY_PROJECT_DETAIL_FOO_BAR_HPP',
  '',
  '// The define is intentionally separated from ifndef.',
  '# define MY_PROJECT_DETAIL_FOO_BAR_HPP // public header',
  '',
  'class A {};',
  '',
  '# endif // MY_PROJECT_DETAIL_FOO_BAR_HPP',
})

vim.cmd('enew!')
vim.api.nvim_buf_set_name(0, '/tmp/proj/include/value.hpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '#ifndef OLD_VALUE_HPP',
  '#define OLD_VALUE_HPP',
  '',
  '#if FEATURE',
  'class Feature {};',
  '#endif',
  '',
  '#endif /* OLD_VALUE_HPP */',
})
ts_cpp.correct_include_guard()
assert_lines({
  '#ifndef PROJ_VALUE_HPP',
  '#define PROJ_VALUE_HPP',
  '',
  '#if FEATURE',
  'class Feature {};',
  '#endif',
  '',
  '#endif /* PROJ_VALUE_HPP */',
})

-- An unmatched conditional is not sufficiently safe to rewrite as a guard.
vim.cmd('enew!')
vim.api.nvim_buf_set_name(0, '/tmp/proj/include/broken.hpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '#ifndef OLD_BROKEN_HPP',
  '#define OLD_BROKEN_HPP',
  'class Broken {};',
})
ts_cpp.correct_include_guard()
assert_lines({
  '#ifndef OLD_BROKEN_HPP',
  '#define OLD_BROKEN_HPP',
  'class Broken {};',
})

-- A conditional include is not a safe insertion point for an unconditional
-- dependency inferred from code outside the conditional.
set_lines({
  '#if FEATURE',
  '#include <vector>',
  '#endif',
  '',
  'std::vector<int> xs;',
})
include_necessary_types()
assert_lines({
  '#include <vector>',
  '',
  '#if FEATURE',
  '#include <vector>',
  '#endif',
  '',
  'std::vector<int> xs;',
})

-- New includes remain inside a conventional guard even when there is no blank
-- line after its #define.
set_lines({
  '#ifndef FOO_HPP',
  '#define FOO_HPP',
  'std::vector<int> xs;',
  '#endif',
})
include_necessary_types()
assert_lines({
  '#ifndef FOO_HPP',
  '#define FOO_HPP',
  '#include <vector>',
  '',
  'std::vector<int> xs;',
  '#endif',
})

-- #pragma once is another file preamble marker and stays before inferred
-- includes, including when no blank line follows it.
set_lines({
  '// Copyright 2026',
  '#pragma once',
  'std::vector<int> xs;',
})
include_necessary_types()
assert_lines({
  '// Copyright 2026',
  '#pragma once',
  '#include <vector>',
  '',
  'std::vector<int> xs;',
})

-- Leading license comments are part of the file preamble, not a reason to
-- place an inferred include outside the guard.
set_lines({
  '/* Copyright 2026',
  ' * Example Corp.',
  ' */',
  '',
  '#ifndef COMMENTED_HPP',
  '#define COMMENTED_HPP',
  '',
  'std::string value;',
  '#endif',
})
include_necessary_types()
assert_lines({
  '/* Copyright 2026',
  ' * Example Corp.',
  ' */',
  '',
  '#ifndef COMMENTED_HPP',
  '#define COMMENTED_HPP',
  '',
  '#include <string>',
  '',
  'std::string value;',
  '#endif',
})

-- User mappings are call-local and must not mutate the cached built-in table.
local builtin_includes = require('srydell.data.types_to_headers')
assert(builtin_includes['project::Widget'] == nil)
set_lines({ 'project::Widget widget;' })
include_necessary_types({ ['project::Widget'] = '"project/widget.hpp"' })
assert(builtin_includes['project::Widget'] == nil, 'user include leaked into the cached built-in mapping')
assert_lines({
  '#include "project/widget.hpp"',
  '',
  'project::Widget widget;',
})

-- Comments and preprocessor directives between include groups do not disable
-- inference. The existing layout is preserved because sorting remains
-- deliberately conservative when non-include content separates the groups.
set_lines({
  '# include <string>',
  '// Keep this comment with the following include.',
  '#define KEEP_THIS_LAYOUT 1',
  '#  include <utility>',
  '',
  'std::vector<int> xs;',
})
include_necessary_types()
assert_lines({
  '#include <vector>',
  '# include <string>',
  '// Keep this comment with the following include.',
  '#define KEEP_THIS_LAYOUT 1',
  '#  include <utility>',
  '',
  'std::vector<int> xs;',
})

-- Flexible directive spacing is recognized by the sorter as include content.
set_lines({
  '# include <vector>',
  '#  include <string>',
  '',
  'std::vector<int> xs;',
})
ts_cpp.divide_and_sort_includes()
assert_lines({
  '#include <string>',
  '#include <vector>',
  '',
  'std::vector<int> xs;',
})

-- Unqualified types and functions resolve through a visible using-directive.
set_lines({
  'using namespace std;',
  '',
  'vector<int> xs;',
  'move(xs);',
})
include_necessary_types()
assert_lines({
  '#include <utility>',
  '#include <vector>',
  '',
  'using namespace std;',
  '',
  'vector<int> xs;',
  'move(xs);',
})

-- An explicit using-declaration provides stronger, symbol-specific evidence.
set_lines({
  'using std::string;',
  '',
  'string value;',
})
include_necessary_types()
assert_lines({
  '#include <string>',
  '',
  'using std::string;',
  '',
  'string value;',
})

-- using-declarations only apply after their declaration and inside their
-- lexical scope.
set_lines({
  'vector<int> before;',
  'void function() {',
  '  using namespace std;',
  '  vector<int> inside;',
  '}',
  'string outside;',
})
include_necessary_types()
assert_lines({
  '#include <vector>',
  '',
  'vector<int> before;',
  'void function() {',
  '  using namespace std;',
  '  vector<int> inside;',
  '}',
  'string outside;',
})

-- The vector before the using-directive and string outside its compound scope
-- do not match. The include above is required only by vector inside function().
-- Ambiguous namespace imports are intentionally ignored.
set_lines({
  'using namespace first;',
  'using namespace second;',
  '',
  'Thing value;',
})
include_necessary_types({
  ['first::Thing'] = '"first/thing.hpp"',
  ['second::Thing'] = '"second/thing.hpp"',
})
assert_lines({
  'using namespace first;',
  'using namespace second;',
  '',
  'Thing value;',
})

-- Member calls and unknown bare identifiers are not function candidates.
set_lines({
  'using namespace std;',
  '',
  'object.move();',
  'int move = 0;',
})
include_necessary_types()
assert_lines({
  'using namespace std;',
  '',
  'object.move();',
  'int move = 0;',
})

print('cpp_header_regression: ok')
