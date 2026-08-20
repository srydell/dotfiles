-- ":StructLayout" - dump the memory layout (offsets, padding, size, align)
-- of the struct/class/union under the cursor, to spot alignment/packing
-- inefficiencies.
--
-- Two-phase strategy:
--   Phase A (host clang): compiles a scratch copy of the buffer, with a
--   `static_assert(sizeof(::Qualified::Name) > 0, ...)` appended, using
--   `clang++ -Xclang -fdump-record-layouts -fsyntax-only` and the project's
--   own compile_commands.json flags (see srydell.util.compile_commands).
--   Fast, no extra setup, but can fail to parse Linux/toolchain-specific
--   headers on a non-Linux host.
--
--   Phase B (docker + pahole fallback): if Phase A's clang invocation didn't
--   produce a layout for the target type (compile error, missing headers,
--   ...) and the buffer's compile_commands.json entry is available, fall
--   back to compiling with the *actual* project compiler inside a running
--   Docker container (via srydell.util.docker_container) and dumping the
--   resulting DWARF debug info with `pahole -C <name>` - accurate for
--   Linux-only/cross-compiled projects such as dsf, at the cost of needing
--   Docker + the `dwarves` package (pahole) inside the container.
--
-- Optional overrides (only needed if the container does not bind-mount the
-- project at the same absolute path as the host):
--   vim.g.struct_layout_local_root  - host path prefix to replace
--   vim.g.struct_layout_remote_root - its equivalent path inside the container
local compile_commands = require('srydell.util.compile_commands')
local docker_container = require('srydell.util.docker_container')
local ts_struct_layout = require('srydell.treesitter.cpp.struct_layout')

local M = {}

local function notify(msg, level, detail)
  if detail and detail ~= '' then
    msg = msg .. '\n\nDetails:\n' .. detail
  end
  vim.schedule(function()
    vim.notify(msg, level, { title = 'Struct Layout' })
  end)
end

-- Split clang's `-fdump-record-layouts` stdout into per-record blocks and
-- return the one whose header line matches `kind .. ' ' .. name`
-- (e.g. "struct ns::Outer::Inner"), or nil.
function M.extract_layout_block(stdout, kind, name)
  local marker = '*** Dumping AST Record Layout'
  local wanted_header = ('%s %s'):format(kind, name)

  local blocks = {}
  local current = nil
  for line in (stdout or ''):gmatch('([^\n]*)\n?') do
    if line == marker then
      if current then
        table.insert(blocks, table.concat(current, '\n'))
      end
      current = { line }
    elseif current then
      table.insert(current, line)
    end
  end
  if current then
    table.insert(blocks, table.concat(current, '\n'))
  end

  for _, block in ipairs(blocks) do
    -- Header line looks like: "         0 | struct ns::Outer::Inner"
    local header = block:match('%d+ | ([^\n]+)')
    if header == wanted_header then
      -- Trim the trailing blank line dump blocks end with.
      return vim.trim(block)
    end
  end
  return nil
end

local function display(lines, title)
  if type(lines) == 'string' then
    lines = vim.split(lines, '\n', { plain = true })
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  width = math.min(math.max(width + 2, #title + 4), math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines + 1, math.floor(vim.o.lines * 0.8))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  vim.wo[win].wrap = false

  for _, lhs in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', lhs, '<cmd>close<CR>', { buffer = buf, silent = true })
  end
end

local function write_scratch_source(filepath, injected_assert)
  local dir = vim.fs.dirname(filepath)
  local ext = vim.fn.fnamemodify(filepath, ':e')
  local scratch_path =
    vim.fs.joinpath(dir, ('.struct_layout_tmp_%d.%s'):format(vim.fn.getpid(), ext ~= '' and ext or 'cpp'))

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  table.insert(lines, injected_assert)
  vim.fn.writefile(lines, scratch_path)
  return scratch_path
end

local function remote_path(path)
  local local_root = vim.g.struct_layout_local_root
  local remote_root = vim.g.struct_layout_remote_root
  if not local_root or not remote_root then
    return path
  end
  if vim.startswith(path, local_root) then
    return remote_root .. path:sub(#local_root + 1)
  end
  return path
end

-- Phase B: compile with the project's real compiler inside a running Docker
-- container, then read the layout back out of the DWARF debug info with
-- pahole. Only usable when a compile_commands.json entry (with its own
-- compiler/args/directory) was resolved for this file.
local function run_docker_pahole(info, entry, scratch_path, on_done)
  docker_container.with_container(function(container)
    if not container then
      on_done(nil, 'Docker fallback unavailable; see the error above.')
      return
    end

    local args = entry.arguments
    if not args and entry.command then
      args = vim.split(entry.command, '%s+')
    end
    if not args or #args == 0 then
      on_done(nil, 'compile_commands.json entry has neither "arguments" nor "command".')
      return
    end

    local remote_dir = remote_path(entry.directory)
    local remote_scratch = remote_path(scratch_path)
    local remote_obj = ('/tmp/struct_layout_%d.o'):format(vim.fn.getpid())

    local remote_args = { args[1] } -- keep the project's real compiler
    local skip_next = false
    for i = 2, #args do
      local arg = args[i]
      if skip_next then
        skip_next = false
      elseif arg == entry.file then
        table.insert(remote_args, remote_scratch)
      elseif arg == '-c' then
        -- re-added explicitly below
      elseif arg == '-o' then
        skip_next = true
      elseif arg:match('^%-o') then
        -- combined -oFILE, dropped
      else
        table.insert(remote_args, arg)
      end
    end
    vim.list_extend(remote_args, { '-w', '-g', '-c', '-o', remote_obj })

    local exec_args = { 'docker', 'exec', '-w', remote_dir, container }
    vim.list_extend(exec_args, remote_args)

    vim.system(exec_args, { text = true }, function(compile_result)
      if compile_result.code ~= 0 then
        on_done(
          nil,
          ('Compiling inside container %s failed.'):format(container),
          vim.trim(compile_result.stderr or '')
        )
        return
      end

      local pahole_name = ('%s %s'):format(info.kind, info.name)
      vim.system(
        { 'docker', 'exec', container, 'pahole', '-C', info.name, remote_obj },
        { text = true },
        function(pahole_result)
          vim.system({ 'docker', 'exec', container, 'rm', '-f', remote_obj }, { text = true }, function() end)

          if pahole_result.code == 127 then
            on_done(
              nil,
              ("pahole is not installed inside container %s."):format(container),
              "Install it with the container's package manager, e.g. apt-get install dwarves."
            )
            return
          end
          if pahole_result.code ~= 0 or vim.trim(pahole_result.stdout or '') == '' then
            on_done(
              nil,
              ('pahole could not find %s in the compiled object.'):format(pahole_name),
              vim.trim(pahole_result.stderr or '')
            )
            return
          end
          on_done(vim.trim(pahole_result.stdout))
        end
      )
    end)
  end, { title = 'Struct Layout' })
end

-- Show the memory layout of the struct/class/union under the cursor.
function M.show()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == '' then
    notify('The current buffer has no file on disk.', vim.log.levels.WARN)
    return
  end
  filepath = vim.fn.fnamemodify(filepath, ':p')

  local info, err = ts_struct_layout.get_qualified_name_under_cursor()
  if not info then
    notify(err, vim.log.levels.WARN)
    return
  end

  local resolved = compile_commands.get_flags(filepath)
  local scratch_path = write_scratch_source(filepath, ('static_assert(sizeof(::%s) > 0, "struct_layout_marker");'):format(info.name))

  local args = { 'clang++', '-x', 'c++', '-fsyntax-only', '-Xclang', '-fdump-record-layouts' }
  vim.list_extend(args, resolved.flags)
  table.insert(args, scratch_path)

  vim.system(args, { text = true, cwd = resolved.directory }, function(result)
    local block = M.extract_layout_block(result.stdout, info.kind, info.name)

    local function cleanup()
      pcall(os.remove, scratch_path)
    end

    if block then
      cleanup()
      vim.schedule(function()
        display(block, ('%s %s'):format(info.kind, info.name))
      end)
      return
    end

    -- Phase A failed (parse error, or the flags don't cover this TU well
    -- enough to reach the target type). Fall back to compiling with the
    -- project's real compiler inside its Docker container, if we have a
    -- real compile_commands.json entry to work with.
    if not resolved.entry then
      cleanup()
      notify(
        'clang could not produce a layout for ' .. info.kind .. ' ' .. info.name .. ', and no compile_commands.json entry was available for the Docker fallback.',
        vim.log.levels.ERROR,
        vim.trim(result.stderr or '')
      )
      return
    end

    notify(
      'Host clang could not parse this file (probably platform-specific headers); retrying inside the project\'s Docker container...',
      vim.log.levels.INFO,
      vim.trim(result.stderr or '')
    )

    run_docker_pahole(info, resolved.entry, scratch_path, function(pahole_output, problem, detail)
      cleanup()
      if pahole_output then
        vim.schedule(function()
          display(pahole_output, ('%s %s (pahole)'):format(info.kind, info.name))
        end)
      else
        notify(problem, vim.log.levels.ERROR, detail)
      end
    end)
  end)
end

return M
