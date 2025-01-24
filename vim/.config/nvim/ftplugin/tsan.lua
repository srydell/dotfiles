local function filter_tsan(opts)
  opts = opts or {}
  local cmd = {
    'python3',
    vim.fn.stdpath('config') .. '/tools/filter_tsan.py',
    '--filename',
    vim.fn.expand('%:p'),
  }

  if opts.remove_containing then
    table.insert(cmd, '--remove-containing')
    table.insert(cmd, opts.remove_containing)
  end

  if opts.keep_containing then
    table.insert(cmd, '--keep-containing')
    table.insert(cmd, opts.keep_containing)
  end

  if opts.as_json then
    table.insert(cmd, '--as-json')
  end

  return cmd
end

local function run_and_set(cmd)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.fn.systemlist(cmd))
end

local function no_filter()
  run_and_set(filter_tsan())
  vim.api.nvim_command('write')
end

local function remove_containing()
  local cmd = filter_tsan({ remove_containing = vim.fn.input('Remove containing: ') })
  run_and_set(cmd)
  vim.api.nvim_command('write')
end

local function keep_containing()
  local cmd = filter_tsan({ keep_containing = vim.fn.input('Keep containing: ') })
  run_and_set(cmd)
  vim.api.nvim_command('write')
end

-- Returns a list of thread names
-- Input = { T11 = 'main', T12 = 'event_listener' }
-- Output = '{main, event_listener}'
local function get_thread_names(thread_names)
  local names = ''
  for _, thread_name in pairs(thread_names) do
    if names == '' then
      names = thread_name
    else
      names = names .. ' ' .. thread_name
    end
  end
  return '{' .. names .. '}'
end

local function get_valid_file(filename)
  local exists = false
  if vim.fn.exists(filename) == 1 then
    exists = true
  elseif filename:sub(1, 3) == '../' then
    local name = filename
    -- If it begins with '..',
    while name:sub(1, 3) == '../' do
      -- Is it relative to the current working directory?
      -- ../hello.cpp -> ./hello.cpp
      if vim.fn.filereadable(name:sub(2)) == 1 then
        filename = name:sub(2)
        exists = true
        return { exists = exists, name = filename }
      -- Is it in a nearby library?
      -- ../source/hello.cpp -> ../oal/hello.cpp
      elseif name:sub(1, 9) == '../source' and vim.fn.filereadable('../oal' .. name:sub(10)) == 1 then
        filename = '../oal' .. name:sub(10)
        exists = true
        return { exists = exists, name = filename }
      end

      -- ../hello.cpp -> hello.cpp
      name = name:sub(4)
    end
  end
  return { exists = exists, name = filename }
end

local function load_tsan_into_quickfix()
  -- Run filter_tsan on the current buffer
  local output =
    vim.json.decode(vim.fn.system(filter_tsan({ as_json = true })), { luanil = { object = true, array = true } })

  -- The interface for qlist is:
  -- items = {
  --   { filename = 'a.txt', lnum = 10, text = 'Apple' },
  --   { text = 'only text' },
  -- }
  local items = {}
  for _, tsan_warning in ipairs(output) do
    table.insert(items, { text = tsan_warning['warning'] .. get_thread_names(tsan_warning['thread_names']) })
    for _, stack in ipairs(tsan_warning['stacks']) do
      local thread_name = tsan_warning['thread_names'][stack['thread']]
      if thread_name ~= nil then
        table.insert(items, { text = stack['header'] .. ' ' .. thread_name })
      else
        table.insert(items, { text = stack['header'] })
      end

      -- One of:
      -- {
      --   f = "[failed to restore the stack]"
      -- }
      -- {
      --   depth = "#0",
      --   f = "vsnprintf"
      -- }
      -- {
      --   depth = "#1",
      --   filename = "../../../../source/src/oal_log.cpp",
      --   f = "default_sink",
      --   linenumber = "77"
      -- }
      for _, frame in ipairs(stack['frames']) do
        local text = ''
        if frame['depth'] == nil then
          -- No frame, only function data
          table.insert(items, { text = frame['f'] })
        elseif frame['filename'] == nil then
          -- No filename, probably standard function
          table.insert(items, { text = frame['depth'] .. ' ' .. frame['f'] })
        else
          -- Known function and filename
          local file = get_valid_file(frame['filename'])
          if file.exists then
            table.insert(items, {
              filename = file.name,
              lnum = frame['linenumber'],
              text = frame['depth'] .. ' ' .. frame['f'],
            })
          else
            -- Make a nice-ish line to jump over
            table.insert(items, {
              text = frame['depth'] .. ' ' .. frame['f'] .. ' ' .. frame['filename'] .. ':' .. frame['linenumber'],
            })
          end
        end
      end
    end
    table.insert(items, { text = tsan_warning['summary'] })
  end

  -- Replace the current quickfix list with this one
  local id = vim.fn.getqflist({ id = 0 }).id
  vim.fn.setqflist({}, 'r', { id = id, title = 'TSAN output', items = items })

  -- Open the quickfix list
  vim.cmd('copen')
end

local function is_stack_trace(text)
  -- Stack traces start with '#<number> '
  return text:match('#%d+ ') ~= nil or text:match('failed to restore the stack') ~= nil
end

local function goto_stack(increment)
  local qlist = vim.fn.getqflist()
  local current_index = vim.fn.getqflist({ idx = 0 }).idx
  local line = qlist[current_index]
  if is_stack_trace(line.text) then
    -- search until no stack trace
    while is_stack_trace(line.text) do
      current_index = current_index + increment
      line = qlist[current_index]
      -- End of qlist
      if line == nil then
        return
      end
    end
  end

  -- search until next stack trace
  while not is_stack_trace(line.text) do
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- if we're going up, we are now at the bottom of the trace (e.g. #15)
  -- Have to get to #0
  if increment == -1 then
    while is_stack_trace(line.text) do
      current_index = current_index + increment
      line = qlist[current_index]
      -- End of qlist
      if line == nil then
        return
      end
    end
    -- Go down to #0 again
    current_index = current_index + 1
  end

  -- Goto our new stack trace
  vim.cmd('cc ' .. current_index)
end

local function goto_previous_stack()
  goto_stack(-1)
end

local function goto_next_stack()
  goto_stack(1)
end

local function is_tsan_warning(text)
  return text:match('WARNING: ThreadSanitizer:') ~= nil
end

local function goto_tsan_warning(increment)
  local qlist = vim.fn.getqflist()
  local current_index = vim.fn.getqflist({ idx = 0 }).idx
  local line = qlist[current_index]

  if is_tsan_warning(line.text) then
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- search until we find a new warning
  while not is_tsan_warning(line.text) do
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- Goto our new tsan warning
  vim.cmd('cc ' .. current_index)
end

local function goto_next_tsan_warning()
  goto_tsan_warning(1)
end

local function goto_previous_tsan_warning()
  goto_tsan_warning(-1)
end

vim.keymap.set('n', '<leader>aa', no_filter, { buffer = true })
vim.keymap.set('n', '<leader>af', remove_containing, { buffer = true })
vim.keymap.set('n', '<leader>ac', keep_containing, { buffer = true })
vim.keymap.set('n', '<leader>aq', load_tsan_into_quickfix, { buffer = true })
vim.keymap.set('n', ']s', goto_next_stack, { buffer = false })
vim.keymap.set('n', '[s', goto_previous_stack, { buffer = false })
vim.keymap.set('n', ']w', goto_next_tsan_warning, { buffer = false })
vim.keymap.set('n', '[w', goto_previous_tsan_warning, { buffer = false })
