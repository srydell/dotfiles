-- Run with:
-- $ nvim --headless -u init.lua -l tests/cpp_treesitter_fixes_regression.lua
--
-- Regression coverage for a batch of bug fixes in
-- lua/srydell/treesitter/cpp.lua:
--   1. noexcept must survive when generating a definition from a declaration.
--   2. make_atomic_load() must only wrap the identifier, never the whole
--      parameter_declaration.
--   3. make_class_no_move()/make_class_no_copy() must emit valid C++ (a
--      comment, not a bare line of text) with canonical signatures, and
--      no-move must be noexcept by default.
--   4. The four make_enum_* generators were refactored to share a common
--      case-builder; verify their output is unchanged.
--   5. find_enum_from_type() must not error when the reported LSP location
--      does not exist in the target buffer.
local ts_cpp = require('srydell.treesitter.cpp')

local function set_lines(lines)
  vim.cmd('enew!')
  vim.bo.filetype = 'cpp'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.treesitter.get_parser(0, 'cpp'):parse()
  return vim.api.nvim_get_current_buf()
end

local function assert_lines(expected, message)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(
    vim.deep_equal(actual, expected),
    string.format(
      '%s\nexpected:\n%s\nactual:\n%s',
      message,
      table.concat(expected, '\n'),
      table.concat(actual, '\n')
    )
  )
end

-- 1. noexcept must be preserved when building a definition snippet from a
-- declaration.
do
  local source_buf = set_lines({
    'struct Foo {',
    '  void bar() noexcept;',
    '};',
  })

  local function_node = ts_cpp.search_down_from_root_until(ts_cpp.is_function, source_buf)
  assert(function_node ~= nil, 'expected to find the bar() function_declarator node')

  local snippet_node = ts_cpp.build_function_snippet({ node = function_node, buffer = source_buf })
  assert(snippet_node ~= nil, 'build_function_snippet should produce a snippet node for a noexcept declaration')

  vim.cmd('enew!')
  vim.bo.filetype = 'cpp'
  local ls = require('luasnip')
  ls.snip_expand(ls.snippet({}, { snippet_node }), { pos = { 0, 0 } })

  local produced = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  assert(produced:find('Foo::bar', 1, true) ~= nil, 'definition should be qualified with the class name: ' .. produced)
  assert(produced:find('noexcept', 1, true) ~= nil, 'noexcept must be kept on the generated definition: ' .. produced)
end

-- 2. make_atomic_load() must only wrap the identifier of a parameter, not the
-- whole 'Type name' declaration, no matter where in the parameter the cursor
-- lands.
do
  set_lines({ 'void f(int value);' })
  -- Column 7 is the 'i' of 'int' - i.e. the cursor is on the parameter's
  -- type, not its identifier. This used to make is_variable() match the
  -- whole parameter_declaration node and wrap all of 'int value'.
  vim.api.nvim_win_set_cursor(0, { 1, 7 })
  ts_cpp.make_atomic_load()
  assert(
    vim.api.nvim_get_current_line() == 'void f(int value.load(std::memory_order_acquire));',
    'make_atomic_load from the parameter type should only wrap the identifier: ' .. vim.api.nvim_get_current_line()
  )

  set_lines({ 'void f(int value);' })
  -- Cursor directly on the identifier should keep working as before.
  vim.api.nvim_win_set_cursor(0, { 1, 11 })
  ts_cpp.make_atomic_load()
  assert(
    vim.api.nvim_get_current_line() == 'void f(int value.load(std::memory_order_acquire));',
    'make_atomic_load from the parameter identifier should wrap only the identifier: '
      .. vim.api.nvim_get_current_line()
  )
end

-- 3. make_class_no_move()/make_class_no_copy() must emit a comment (not bare
-- text) and canonical, noexcept-by-default move signatures.
do
  set_lines({
    'class Foo {',
    '',
    '};',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  ts_cpp.make_class_no_move()
  assert_lines({
    'class Foo {',
    '',
    '// No move',
    'Foo(Foo &&) noexcept = delete;',
    'Foo & operator=(Foo &&) noexcept = delete;',
    '};',
  }, 'make_class_no_move output mismatch')
end

do
  set_lines({
    'class Foo {',
    '',
    '};',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  ts_cpp.make_class_no_copy()
  assert_lines({
    'class Foo {',
    '',
    '// No copy',
    'Foo(Foo const &) = delete;',
    'Foo & operator=(Foo const &) = delete;',
    '};',
  }, 'make_class_no_copy output mismatch')
end

-- 4. The enum generators were refactored to share a case-builder; output
-- must be unchanged.
do
  set_lines({
    'enum class Color {',
    '  Red,',
    '  Green,',
    '};',
    '',
    'Color c;',
  })
  vim.api.nvim_win_set_cursor(0, { 1, 12 })
  ts_cpp.make_enum_stringify()
  assert_lines({
    'enum class Color {',
    '  Red,',
    '  Green,',
    '};',
    'std::string to_string(Color e) {',
    '  switch (e) {',
    '  case Color::Red: {',
    '    return "Color::Red";',
    '  }',
    '  case Color::Green: {',
    '    return "Color::Green";',
    '  }',
    '  }',
    '  return "Unknown";',
    '}',
    '',
    'Color c;',
  }, 'make_enum_stringify output mismatch after refactor')
end

-- 5. find_enum_from_type() must not error when the LSP-reported line does not
-- exist in the target buffer (nil-safety around lines[1]).
do
  set_lines({ 'int not_an_enum;' })

  local original_buf_request_sync = vim.lsp.buf_request_sync
  local original_bufadd = vim.fn.bufadd
  local original_bufloaded = vim.fn.bufloaded
  local original_bufload = vim.fn.bufload

  local target_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(target_buf, 0, -1, false, { 'enum class E { A };' })
  local target_name = vim.api.nvim_buf_get_name(target_buf)
  if target_name == '' then
    target_name = '/tmp/cpp_treesitter_fixes_regression_target.hpp'
    vim.api.nvim_buf_set_name(target_buf, target_name)
  end

  -- Point the mocked LSP response far past the end of the target buffer so
  -- `nvim_buf_get_lines` returns an empty table and `lines[1]` is nil.
  vim.lsp.buf_request_sync = function()
    return {
      {
        result = {
          {
            uri = 'file://' .. target_name,
            range = {
              start = { line = 9999, character = 0 },
              ['end'] = { line = 9999, character = 1 },
            },
          },
        },
      },
    }
  end
  vim.fn.bufadd = function()
    return target_buf
  end
  vim.fn.bufloaded = function()
    return 1
  end
  vim.fn.bufload = function() end

  local ok, result = pcall(ts_cpp.find_enum_from_type)

  vim.lsp.buf_request_sync = original_buf_request_sync
  vim.fn.bufadd = original_bufadd
  vim.fn.bufloaded = original_bufloaded
  vim.fn.bufload = original_bufload

  assert(ok, 'find_enum_from_type should not error on an out-of-range LSP location: ' .. tostring(result))
  assert(result == nil, 'find_enum_from_type should return nil when the reported location is out of range')
end

print('cpp_treesitter_fixes_regression: ok')
