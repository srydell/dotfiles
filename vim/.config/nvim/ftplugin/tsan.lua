local function filter_tsan(filter, as_json)
  local cmd = {
    'python3',
    vim.fn.stdpath('config') .. '/tools/filter_tsan.py',
    '--filename',
    vim.fn.expand('%:p'),
  }

  if filter then
    table.insert(cmd, '--remove-containing')
    table.insert(cmd, filter)
  end

  if as_json then
    table.insert(cmd, '--as-json')
  end

  return cmd
end

local function run_and_set(cmd)
  local filtered_content = vim.fn.systemlist(cmd)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, filtered_content)
end

local function no_filter()
  run_and_set(filter_tsan())
  vim.api.nvim_command('write')
end

local function remove_containing()
  local cmd = filter_tsan(vim.fn.input('Remove containing: '))
  run_and_set(cmd)
  vim.api.nvim_command('write')
end

local function get_thread_names(thread_names)
  local out = ''
  for _, thread_name in pairs(thread_names) do
    if out == '' then
      out = thread_name
    else
      out = out .. ' ' .. thread_name
    end
  end
  return '{' .. out .. '}'
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

local function set_quickfix_list()
  local filter = nil
  local as_json = true
  local output =
    vim.json.decode(vim.fn.system(filter_tsan(filter, as_json)), { luanil = { object = true, array = true } })

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

  local id = vim.fn.getqflist({ id = 0 }).id
  vim.fn.setqflist({}, 'r', { id = id, title = 'TSAN output', items = items })

  -- Open the quickfix list
  vim.cmd('copen')
end

vim.keymap.set('n', '<leader>aa', no_filter)
vim.keymap.set('n', '<leader>af', remove_containing)
vim.keymap.set('n', '<leader>aq', set_quickfix_list)
