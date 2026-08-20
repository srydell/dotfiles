-- Run with:
-- $ nvim --headless -u init.lua -l tests/struct_layout_pipeline.lua
--
-- End-to-end coverage of lua/srydell/util/struct_layout.lua's M.show()
-- orchestration, with vim.system and the Docker container picker mocked out
-- so the test is hermetic (no real clang/docker/pahole invocation):
--   1. Phase A (host clang) succeeds -> the matching layout block is shown
--      and the scratch source file is cleaned up.
--   2. Phase A fails and there is no compile_commands.json entry to hand to
--      the Docker fallback -> a single clear error notification, and the
--      Docker container picker is never invoked.
--   3. Phase A fails but a compile_commands.json entry exists -> Phase B
--      compiles inside the (mocked) container with the *original* compiler
--      and flags, filters the object file through `pahole -C <name>`, shows
--      its output, and cleans up both the host scratch file and the
--      container's temporary object file.
local struct_layout = require('srydell.util.struct_layout')
local docker_container = require('srydell.util.docker_container')

local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
  return path
end

local function write_file(path, contents)
  if type(contents) == 'string' then
    contents = vim.split(contents, '\n', { plain = true })
  end
  vim.fn.writefile(contents, path)
end

local function write_json(path, value)
  vim.fn.writefile({ vim.json.encode(value) }, path)
end

-- Find the most recently created scratch ('nofile') buffer, i.e. the one the
-- floating window displayed the layout in.
local function latest_scratch_buffer_lines()
  local last = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'nofile' then
      last = buf
    end
  end
  assert(last ~= nil, 'expected a scratch buffer to have been created for the layout display')
  return table.concat(vim.api.nvim_buf_get_lines(last, 0, -1, false), '\n')
end

local function open_source(path, lines)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.bo.filetype = 'cpp'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.treesitter.get_parser(0, 'cpp'):parse()
  vim.api.nvim_win_set_cursor(0, { 2, 4 }) -- inside "int a;"
end

local function capture_notifications()
  local notifications = {}
  local original_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(notifications, { msg = msg, level = level, opts = opts })
  end
  return notifications, function()
    vim.notify = original_notify
  end
end

-- 1. Phase A succeeds: clang produces a matching layout block.
do
  local project = mkdir(vim.fs.joinpath(root, 'phase_a_success'))
  local source_path = vim.fs.joinpath(project, 'foo.cpp')
  write_file(source_path, { 'struct Foo {', '  int a;', '};' })
  open_source(source_path, { 'struct Foo {', '  int a;', '};' })

  local system_calls = {}
  local original_system = vim.system
  vim.system = function(args, opts, callback)
    table.insert(system_calls, args)
    assert(args[1] == 'clang++', 'phase A must invoke clang++: ' .. vim.inspect(args))
    callback({
      code = 0,
      stdout = table.concat({
        '*** Dumping AST Record Layout',
        '         0 | struct Foo',
        '         0 |   int a',
        '           | [sizeof=4, dsize=4, align=4,',
        '           |  nvsize=4, nvalign=4]',
        '',
      }, '\n'),
      stderr = '',
    })
  end

  local notifications, restore_notify = capture_notifications()

  struct_layout.show()
  vim.wait(200, function()
    return false
  end)
  vim.system = original_system
  restore_notify()

  assert(#system_calls == 1, 'phase A success must only invoke clang++ once')
  assert(#notifications == 1, 'a successful lookup must only carry the "no db" info notice: ' .. vim.inspect(notifications))
  assert(notifications[1].level == vim.log.levels.INFO, 'the missing-database notice must be INFO level')
  local shown = latest_scratch_buffer_lines()
  assert(shown:find('struct Foo', 1, true) ~= nil, 'expected the Foo layout to be displayed: ' .. shown)
  assert(vim.fn.glob(vim.fs.joinpath(project, '.struct_layout_tmp_*')) == '', 'scratch source file was not cleaned up')
end

-- 2. Phase A fails, no compile_commands.json entry at all -> a single error
-- notification, and Docker must never be consulted.
do
  local project = mkdir(vim.fs.joinpath(root, 'phase_a_fail_no_entry'))
  local source_path = vim.fs.joinpath(project, 'foo.cpp')
  write_file(source_path, { 'struct Foo {', '  int a;', '};' })
  open_source(source_path, { 'struct Foo {', '  int a;', '};' })

  local docker_calls = 0
  local original_with_container = docker_container.with_container
  docker_container.with_container = function()
    docker_calls = docker_calls + 1
  end

  local original_system = vim.system
  vim.system = function(_, _, callback)
    callback({ code = 1, stdout = '', stderr = "fatal error: 'oal_platform.h' file not found" })
  end

  local notifications, restore_notify = capture_notifications()

  struct_layout.show()
  vim.wait(200, function()
    return false
  end)

  vim.system = original_system
  docker_container.with_container = original_with_container
  restore_notify()

  assert(docker_calls == 0, 'the Docker fallback must not run without a compile_commands.json entry')
  assert(#notifications == 2, 'expected the "no db" info notice plus the final error: ' .. vim.inspect(notifications))
  assert(notifications[1].level == vim.log.levels.INFO, 'the missing-database notice must be INFO level')
  assert(notifications[2].level == vim.log.levels.ERROR, 'the failure must be reported as an error')
  assert(
    notifications[2].msg:find('no compile_commands.json entry', 1, true) ~= nil,
    'error message did not explain the missing compile_commands.json entry: ' .. notifications[2].msg
  )
end

-- 3. Phase A fails, but a compile_commands.json entry exists -> Phase B
-- compiles inside the (mocked) container using the *original* compiler and
-- flags, then reads the layout back with pahole.
do
  local project = mkdir(vim.fs.joinpath(root, 'phase_b_success'))
  local source_path = vim.fs.joinpath(project, 'foo.cpp')
  write_file(source_path, { 'struct Foo {', '  int a;', '};' })
  write_json(vim.fs.joinpath(project, 'compile_commands.json'), {
    {
      directory = project,
      file = source_path,
      arguments = { 'g++', '-DFOO=1', source_path, '-c', '-o', 'foo.o' },
    },
  })
  open_source(source_path, { 'struct Foo {', '  int a;', '};' })

  local original_with_container = docker_container.with_container
  docker_container.with_container = function(callback)
    callback('fake-container')
  end

  local pahole_output = table.concat({
    'struct Foo {',
    '\tint  a; /*     0     4 */',
    '',
    '\t/* size: 4, cachelines: 1, members: 1 */',
    '};',
  }, '\n')

  local system_calls = {}
  local original_system = vim.system
  vim.system = function(args, opts, callback)
    table.insert(system_calls, args)
    if args[1] == 'clang++' then
      -- Phase A must still fail first, exactly as it would for a header
      -- pulling in Linux/toolchain-only system headers.
      callback({ code = 1, stdout = '', stderr = "fatal error: 'oal_platform.h' file not found" })
    elseif args[1] == 'docker' and args[2] == 'exec' and vim.tbl_contains(args, 'g++') then
      -- The compile step inside the container: must reuse the *original*
      -- compiler/flags from compile_commands.json (not clang, not
      -- default flags), targeting a private temp object file.
      assert(vim.tbl_contains(args, '-DFOO=1'), 'container compile lost the original -D flag: ' .. vim.inspect(args))
      assert(vim.tbl_contains(args, '-w'), 'container compile must silence warnings/-Werror: ' .. vim.inspect(args))
      assert(vim.tbl_contains(args, '-g'), 'container compile must keep debug info for pahole: ' .. vim.inspect(args))
      assert(not vim.tbl_contains(args, source_path), 'container compile must use the scratch file, not the original source')
      callback({ code = 0, stdout = '', stderr = '' })
    elseif args[1] == 'docker' and args[4] == 'pahole' then
      assert(args[6] == 'Foo', 'pahole must be filtered to the target struct name: ' .. vim.inspect(args))
      callback({ code = 0, stdout = pahole_output, stderr = '' })
    elseif args[1] == 'docker' and args[4] == 'rm' then
      callback({ code = 0, stdout = '', stderr = '' })
    else
      error('unexpected vim.system call: ' .. vim.inspect(args))
    end
  end

  local notifications, restore_notify = capture_notifications()

  struct_layout.show()
  vim.wait(200, function()
    return false
  end)

  vim.system = original_system
  docker_container.with_container = original_with_container
  restore_notify()

  local kinds = {}
  for _, args in ipairs(system_calls) do
    table.insert(kinds, args[1] == 'docker' and (args[4] or args[2]) or args[1])
  end
  assert(#system_calls == 4, 'expected clang, container compile, pahole, and cleanup: ' .. vim.inspect(kinds))

  local shown = latest_scratch_buffer_lines()
  assert(shown == pahole_output, 'expected pahole output to be displayed verbatim:\n' .. shown)

  assert(
    #notifications >= 1 and notifications[1].level == vim.log.levels.INFO,
    'expected an info notification announcing the Docker retry'
  )

  assert(vim.fn.glob(vim.fs.joinpath(project, '.struct_layout_tmp_*')) == '', 'scratch source file was not cleaned up')
end

vim.fn.delete(root, 'rf')
print('struct_layout_pipeline: ok')
