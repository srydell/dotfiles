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

vim.cmd('edit! /tmp/proj/include/foo.h')
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

vim.cmd('edit! /tmp/proj/include/foo.hpp')
vim.bo.filetype = 'cpp'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  '#ifndef OLD_GUARD',
  '#define OLD_GUARD',
  '',
  'class A {};',
  '',
  '#endif',
})
vim.cmd('doautocmd BufWritePre')
assert_lines({
  '#ifndef PROJ_FOO_HPP',
  '#define PROJ_FOO_HPP',
  '',
  'class A {};',
  '',
  '#endif',
})

print('cpp_header_regression: ok')
