-- Run with:
-- $ nvim --headless -u init.lua -l tests/struct_layout_extract_block.lua
--
-- Coverage for lua/srydell/util/struct_layout.lua's
-- extract_layout_block(): pick the `*** Dumping AST Record Layout` block
-- whose header line matches `kind name` out of clang's
-- `-fdump-record-layouts` stdout, which contains one block per record clang
-- happened to lay out (including unrelated ones we must not match).
local struct_layout = require('srydell.util.struct_layout')

local sample_stdout = table.concat({
  '',
  '*** Dumping AST Record Layout',
  '         0 | struct ns::Outer',
  '         0 |   char x',
  '         8 |   int64_t y',
  '        16 |   _Bool z',
  '           | [sizeof=24, dsize=24, align=8,',
  '           |  nvsize=24, nvalign=8]',
  '',
  '*** Dumping AST Record Layout',
  '         0 | struct ns::Outer::Inner',
  '         0 |   char a',
  '         8 |   double b',
  '        16 |   int c',
  '           | [sizeof=24, dsize=24, align=8,',
  '           |  nvsize=24, nvalign=8]',
  '',
  '*** Dumping AST Record Layout',
  '         0 | class ns::Foo',
  '         0 |   int a',
  '         4 |   char b',
  '         8 |   double c',
  '           | [sizeof=16, dsize=16, align=8,',
  '           |  nvsize=16, nvalign=8]',
  '',
}, '\n')

-- Matches the right block out of several, by both kind and fully qualified
-- name - "struct ns::Outer" must not accidentally match "ns::Outer::Inner".
do
  local block = struct_layout.extract_layout_block(sample_stdout, 'struct', 'ns::Outer')
  assert(block ~= nil, 'expected to find the ns::Outer block')
  assert(block:find('*** Dumping AST Record Layout', 1, true), 'block must keep its header marker')
  assert(block:find('struct ns::Outer\n', 1, true) ~= nil, 'wrong block matched for ns::Outer: ' .. block)
  assert(not block:find('Inner', 1, true), 'ns::Outer must not match the nested ns::Outer::Inner block: ' .. block)
end

do
  local block = struct_layout.extract_layout_block(sample_stdout, 'struct', 'ns::Outer::Inner')
  assert(block ~= nil, 'expected to find the ns::Outer::Inner block')
  assert(block:find('struct ns::Outer::Inner', 1, true) ~= nil, 'wrong block matched for Inner: ' .. block)
end

do
  local block = struct_layout.extract_layout_block(sample_stdout, 'class', 'ns::Foo')
  assert(block ~= nil, 'expected to find the ns::Foo block')
  assert(block:find('class ns::Foo', 1, true) ~= nil, 'wrong block matched for Foo: ' .. block)
end

-- The kind must match too - a struct named the same as some class must not
-- cross-match.
do
  local block = struct_layout.extract_layout_block(sample_stdout, 'class', 'ns::Outer')
  assert(block == nil, 'kind mismatch (struct vs class) must not match')
end

-- Nothing found at all (e.g. clang never reached this declaration).
do
  local block = struct_layout.extract_layout_block(sample_stdout, 'struct', 'ns::DoesNotExist')
  assert(block == nil, 'a name absent from the dump must return nil')
end

-- No record layouts at all in the output (e.g. a compile error before any
-- declaration was reached).
do
  local block = struct_layout.extract_layout_block('some error text, no dumps at all', 'struct', 'Foo')
  assert(block == nil, 'stdout without any dump marker must return nil')
end

print('struct_layout_extract_block: ok')
