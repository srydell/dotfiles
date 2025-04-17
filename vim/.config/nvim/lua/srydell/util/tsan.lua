local M = {}

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

M.load_tsan_into_quickfix_from_json = function(output)
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

M.goto_stack = function(increment)
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

M.goto_previous_stack = function()
  M.goto_stack(-1)
end

M.goto_next_stack = function()
  M.goto_stack(1)
end

M.is_tsan_warning = function(text)
  return text:match('WARNING: ThreadSanitizer:') ~= nil
end

M.goto_tsan_warning = function(increment)
  local qlist = vim.fn.getqflist()
  local current_index = vim.fn.getqflist({ idx = 0 }).idx
  local line = qlist[current_index]

  if M.is_tsan_warning(line.text) then
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- search until we find a new warning
  while not M.is_tsan_warning(line.text) do
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

M.goto_next_tsan_warning = function()
  M.goto_tsan_warning(1)
end

M.goto_previous_tsan_warning = function()
  M.goto_tsan_warning(-1)
end

return M
