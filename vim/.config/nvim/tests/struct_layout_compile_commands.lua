-- Run with:
-- $ nvim --headless -u init.lua -l tests/struct_layout_compile_commands.lua
--
-- Coverage for lua/srydell/util/compile_commands.lua: locating
-- compile_commands.json (directly, or via .clangd's CompilationDatabase),
-- matching a file to its database entry (exact, or the nearest-directory
-- approximation for headers with no compiled sibling), cleaning compiler
-- arguments down to reusable flags, and the fallback-to-defaults path with
-- its info notification.
local compile_commands = require('srydell.util.compile_commands')
local cpp_helpers = require('srydell.compiler.helpers.cpp')

local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
  return path
end

local function write_json(path, value)
  vim.fn.writefile({ vim.json.encode(value) }, path)
end

local function write_file(path, contents)
  if type(contents) == 'string' then
    contents = vim.split(contents, '\n', { plain = true })
  end
  vim.fn.writefile(contents, path)
end

-- 1. find_database(): a direct compile_commands.json is preferred over a
-- .clangd-referenced one further up the tree.
do
  local project = mkdir(vim.fs.joinpath(root, 'direct_db'))
  local src = mkdir(vim.fs.joinpath(project, 'src'))
  write_json(vim.fs.joinpath(project, 'compile_commands.json'), {})
  write_file(vim.fs.joinpath(src, 'foo.cpp'), 'struct Foo {};')

  local found = compile_commands.find_database(src)
  assert(found == vim.fs.joinpath(project, 'compile_commands.json'), 'expected the project-root database: ' .. tostring(found))
end

-- 2. find_database(): fall back to .clangd's CompilationDatabase mapping
-- when compile_commands.json is not at the project root (e.g. build/debug).
do
  local project = mkdir(vim.fs.joinpath(root, 'clangd_db'))
  local src = mkdir(vim.fs.joinpath(project, 'src'))
  local build_dir = mkdir(vim.fs.joinpath(project, 'build', 'debug'))
  write_json(vim.fs.joinpath(build_dir, 'compile_commands.json'), {})
  write_file(vim.fs.joinpath(project, '.clangd'), 'CompileFlags:\n  CompilationDatabase: build/debug\n')
  write_file(vim.fs.joinpath(src, 'foo.cpp'), 'struct Foo {};')

  local found = compile_commands.find_database(src)
  assert(
    found == vim.fs.joinpath(build_dir, 'compile_commands.json'),
    'expected the .clangd-referenced database: ' .. tostring(found)
  )
end

-- 3. find_database(): nothing found anywhere upward.
do
  local project = mkdir(vim.fs.joinpath(root, 'no_db'))
  local src = mkdir(vim.fs.joinpath(project, 'src'))
  write_file(vim.fs.joinpath(src, 'foo.cpp'), 'struct Foo {};')

  local found = compile_commands.find_database(src)
  assert(found == nil, 'expected no database to be found: ' .. tostring(found))
end

-- 4. find_entry(): exact match wins outright.
do
  local project = mkdir(vim.fs.joinpath(root, 'entries'))
  local entries = {
    {
      directory = project,
      file = 'src/foo.cpp',
      arguments = { 'g++', '-std=c++20', '-I../inc', 'src/foo.cpp', '-c', '-o', 'foo.o' },
    },
    {
      directory = project,
      file = 'src/deep/nested/bar.cpp',
      arguments = { 'g++', '-std=c++17', 'src/deep/nested/bar.cpp', '-c', '-osrc/deep/nested/bar.o' },
    },
  }

  local filepath = vim.fs.joinpath(project, 'src/foo.cpp')
  local entry, is_exact = compile_commands.find_entry(entries, filepath)
  assert(is_exact, 'expected an exact match')
  assert(entry.file == 'src/foo.cpp', 'wrong entry returned for an exact match')
end

-- 5. find_entry(): a header with no compiled sibling in its own directory
-- must fall back to the entry whose source shares the longest common
-- directory prefix (a nested "test/module.cpp"-style TU beats an unrelated
-- top-level one).
do
  local project = mkdir(vim.fs.joinpath(root, 'nearest_entry'))
  local entries = {
    {
      directory = project,
      file = 'src/unrelated/module.cpp',
      arguments = { 'g++', 'src/unrelated/module.cpp', '-c', '-o', 'x.o' },
    },
    {
      directory = project,
      file = 'src/protocol/peer/test/module.cpp',
      arguments = { 'g++', '-I../../src', 'src/protocol/peer/test/module.cpp', '-c', '-o', 'y.o' },
    },
  }

  -- messages.h lives directly in src/protocol/peer, with no .cpp sibling.
  local filepath = vim.fs.joinpath(project, 'src/protocol/peer/messages.h')
  local entry, is_exact = compile_commands.find_entry(entries, filepath)
  assert(not is_exact, 'a header can never be an exact match')
  assert(
    entry.file == 'src/protocol/peer/test/module.cpp',
    'expected the nearest translation unit in the source tree, got: ' .. tostring(entry and entry.file)
  )
end

-- 6. clean_args(): strip the compiler executable, the source file, -c, both
-- spaced and combined -o forms, keep everything else (including flags that
-- merely start with -o's letters, like -O2), and append -w.
do
  local args = {
    'g++',
    '-std=c++20',
    '-O2',
    '-Wall',
    'src/foo.cpp',
    '-c',
    '-o',
    'out.o',
  }
  local cleaned = compile_commands.clean_args(args, 'src/foo.cpp')
  assert(
    vim.deep_equal(cleaned, { '-std=c++20', '-O2', '-Wall', '-w' }),
    'clean_args produced unexpected flags: ' .. table.concat(cleaned, ' | ')
  )

  local combined = { 'g++', '-Wall', 'src/foo.cpp', '-c', '-ofoo/out.o' }
  local cleaned_combined = compile_commands.clean_args(combined, 'src/foo.cpp')
  assert(
    vim.deep_equal(cleaned_combined, { '-Wall', '-w' }),
    'clean_args did not drop a combined -oFILE argument: ' .. table.concat(cleaned_combined, ' | ')
  )
end

-- 7. get_flags(): exact match, approximate match, and default fallback, each
-- reported through the expected `mode` and an info notification for the
-- non-exact cases.
do
  local project = mkdir(vim.fs.joinpath(root, 'get_flags'))
  local src = mkdir(vim.fs.joinpath(project, 'src'))
  write_json(vim.fs.joinpath(project, 'compile_commands.json'), {
    {
      directory = project,
      file = 'src/foo.cpp',
      arguments = { 'g++', '-DFOO=1', vim.fs.joinpath(project, 'src/foo.cpp'), '-c', '-o', 'foo.o' },
    },
  })
  write_file(vim.fs.joinpath(src, 'foo.cpp'), 'struct Foo {};')
  write_file(vim.fs.joinpath(src, 'foo.h'), 'struct Foo {};')

  local notifications = {}
  local original_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(notifications, { msg = msg, level = level, opts = opts })
  end

  local exact = compile_commands.get_flags(vim.fs.joinpath(src, 'foo.cpp'))
  assert(exact.mode == 'exact', 'expected an exact match for foo.cpp')
  assert(vim.tbl_contains(exact.flags, '-DFOO=1'), 'exact match flags missing -DFOO=1')
  assert(#notifications == 0, 'an exact match must not notify')

  local approx = compile_commands.get_flags(vim.fs.joinpath(src, 'foo.h'))
  assert(approx.mode == 'approx', 'expected an approximate match for foo.h')
  assert(#notifications == 1, 'an approximate match must notify once')
  assert(notifications[1].level == vim.log.levels.INFO, 'approximate match notification must be INFO level')

  mkdir(vim.fs.joinpath(root, 'unrelated_dir'))
  local default = compile_commands.get_flags(vim.fs.joinpath(root, 'unrelated_dir', 'unrelated.cpp'))
  assert(default.mode == 'default', 'expected the default fallback outside the project tree')
  assert(default.entry == nil, 'default fallback must not carry a compile_commands entry')
  assert(
    vim.deep_equal(default.flags, cpp_helpers.get_flags('clang', false)),
    'default fallback must reuse the scratch-file compiler flags'
  )
  assert(#notifications == 2, 'the default fallback must add exactly one more notification')
  assert(notifications[2].level == vim.log.levels.INFO, 'default fallback notification must be INFO level')

  vim.notify = original_notify
end

vim.fn.delete(root, 'rf')
print('struct_layout_compile_commands: ok')
