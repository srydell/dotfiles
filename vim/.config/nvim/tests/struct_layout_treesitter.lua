-- Run with:
-- $ nvim --headless -u init.lua -l tests/struct_layout_treesitter.lua
--
-- Coverage for lua/srydell/treesitter/cpp/struct_layout.lua:
-- get_qualified_name_under_cursor() must build the correct `ns::Outer::Inner`
-- name by walking outward through nested classes/namespaces, skip anonymous
-- namespace segments, and reject anonymous records, uninstantiated
-- templates, and cursors outside any record - each with a descriptive error.
local struct_layout = require('srydell.treesitter.cpp.struct_layout')

local function set_lines(lines)
  vim.cmd('enew!')
  vim.bo.filetype = 'cpp'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.treesitter.get_parser(0, 'cpp'):parse()
end

-- Nested struct inside a namespace: cursor inside the inner struct's body
-- must produce the fully qualified name of the innermost record.
do
  set_lines({
    'namespace ns {',
    'struct Outer {',
    '  struct Inner {',
    '    char a;',
    '    double b;',
    '  };',
    '  char x;',
    '};',
    'class Foo { int a; };',
    '}',
  })

  vim.api.nvim_win_set_cursor(0, { 4, 8 }) -- inside Inner's "char a;"
  local info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info ~= nil, 'expected a match for the innermost record: ' .. tostring(err))
  assert(info.name == 'ns::Outer::Inner', 'wrong qualified name for Inner: ' .. info.name)
  assert(info.kind == 'struct', 'wrong kind for Inner: ' .. info.kind)

  vim.api.nvim_win_set_cursor(0, { 7, 4 }) -- inside Outer's own "char x;"
  info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info ~= nil, 'expected a match for Outer: ' .. tostring(err))
  assert(info.name == 'ns::Outer', 'wrong qualified name for Outer: ' .. info.name)
  assert(info.kind == 'struct', 'wrong kind for Outer: ' .. info.kind)

  vim.api.nvim_win_set_cursor(0, { 9, 15 }) -- inside Foo's "int a;"
  info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info ~= nil, 'expected a match for Foo: ' .. tostring(err))
  assert(info.name == 'ns::Foo', 'wrong qualified name for Foo: ' .. info.name)
  assert(info.kind == 'class', 'wrong kind for Foo: ' .. info.kind)
end

-- Anonymous namespaces should not contribute a name segment - their members
-- are visible unqualified, matching how the injected static_assert resolves
-- them at file scope.
do
  set_lines({
    'namespace {',
    'struct Options {',
    '  int histogram;',
    '};',
    '}',
  })
  vim.api.nvim_win_set_cursor(0, { 3, 6 })
  local info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info ~= nil, 'expected a match inside the anonymous namespace: ' .. tostring(err))
  assert(info.name == 'Options', 'anonymous namespace must not appear in the qualified name: ' .. info.name)
end

-- A cursor outside of any struct/class/union must fail with a descriptive
-- error rather than returning a bogus name.
do
  set_lines({ 'int not_a_record;' })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  local info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info == nil, 'cursor outside a record must not match anything')
  assert(err ~= nil and err:find('not inside', 1, true), 'wrong/missing error for a cursor outside a record: ' .. tostring(err))
end

-- Anonymous structs/classes cannot be looked up with sizeof(Name), so they
-- must be rejected with a descriptive error instead of silently producing an
-- unusable/empty name.
do
  set_lines({
    'struct {',
    '  int a;',
    '};',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 4 })
  local info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info == nil, 'anonymous struct must not produce a name')
  assert(err ~= nil and err:find('anonymous', 1, true), 'wrong/missing error for an anonymous struct: ' .. tostring(err))
end

-- Uninstantiated class templates cannot be looked up with a plain
-- sizeof(Name) either; reject them explicitly.
do
  set_lines({
    'template <typename T>',
    'struct Box {',
    '  T value;',
    '};',
  })
  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  local info, err = struct_layout.get_qualified_name_under_cursor()
  assert(info == nil, 'uninstantiated template must not produce a name')
  assert(err ~= nil and err:find('template', 1, true), 'wrong/missing error for an uninstantiated template: ' .. tostring(err))
end

print('struct_layout_treesitter: ok')
