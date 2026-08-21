-- Shared quickfix ingestion + navigation for every `-fsanitize=...` log
-- filetype (tsan/asan/lsan/ubsan). Each ftplugin/<sanitizer>.lua wires this
-- up via srydell.util.sanitizer_buffer, passing the matching tools/filter_*.py
-- script. The JSON schema consumed here is produced by that family of
-- scripts (see tools/sanitizer_common.py): a list of
--   { warning, summary, thread_names, stacks = { { header, thread, frames } } }
local M = {}

-- Returns a list of thread names
-- Input = { T11 = 'main', T12 = 'event_listener' }
-- Output = '{main, event_listener}'
local function get_thread_names(thread_names)
  local names = ''
  for _, thread_name in pairs(thread_names or {}) do
    if names == '' then
      names = thread_name
    else
      names = names .. ' ' .. thread_name
    end
  end
  if names == '' then
    return ''
  end
  return '{' .. names .. '}'
end

local function get_valid_file(filename)
  -- Absolute paths and paths already relative to the cwd (common for
  -- ASan/UBSan, which often don't rewrite paths) can be checked directly.
  if vim.fn.filereadable(filename) == 1 then
    return { exists = true, name = filename }
  end

  -- TSAN (and some ASan builds) report paths relative to a build directory
  -- one level below the cwd, e.g. "../src/foo.cpp".
  if filename:sub(1, 3) == '../' then
    local name = filename
    while name:sub(1, 3) == '../' do
      -- Is it relative to the current working directory?
      -- ../hello.cpp -> ./hello.cpp
      if vim.fn.filereadable(name:sub(2)) == 1 then
        return { exists = true, name = name:sub(2) }
      -- Is it in a nearby library?
      -- ../source/hello.cpp -> ../oal/hello.cpp
      elseif name:sub(1, 9) == '../source' and vim.fn.filereadable('../oal' .. name:sub(10)) == 1 then
        return { exists = true, name = '../oal' .. name:sub(10) }
      end

      -- ../hello.cpp -> hello.cpp
      name = name:sub(4)
    end
  end
  return { exists = false, name = filename }
end

M.load_into_quickfix_from_json = function(output, title)
  -- The interface for qlist is:
  -- items = {
  --   { filename = 'a.txt', lnum = 10, text = 'Apple' },
  --   { text = 'only text' },
  -- }
  local items = {}
  for _, warning in ipairs(output) do
    table.insert(items, { text = warning['warning'] .. get_thread_names(warning['thread_names']) })
    for _, stack in ipairs(warning['stacks']) do
      local thread_name = (warning['thread_names'] or {})[stack['thread']]
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
    table.insert(items, { text = warning['summary'] })
  end

  -- Replace the current quickfix list with this one
  local id = vim.fn.getqflist({ id = 0 }).id
  vim.fn.setqflist({}, 'r', { id = id, title = title or 'Sanitizer output', items = items })

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

-- Matches the first line of any sanitizer report:
--   WARNING: ThreadSanitizer: ...
--   ==1234==ERROR: AddressSanitizer: ...
--   ==1234==ERROR: LeakSanitizer: ...
--   /path/file.cpp:10:5: runtime error: ...   (UndefinedBehaviorSanitizer)
M.is_warning_line = function(text)
  return text:match('%u+: %a+Sanitizer:') ~= nil or text:match(': runtime error: ') ~= nil
end

M.goto_warning = function(increment)
  local qlist = vim.fn.getqflist()
  local current_index = vim.fn.getqflist({ idx = 0 }).idx
  local line = qlist[current_index]

  if M.is_warning_line(line.text) then
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- search until we find a new warning
  while not M.is_warning_line(line.text) do
    current_index = current_index + increment
    line = qlist[current_index]
    -- End of qlist
    if line == nil then
      return
    end
  end

  -- Goto our new warning
  vim.cmd('cc ' .. current_index)
end

M.goto_next_warning = function()
  M.goto_warning(1)
end

M.goto_previous_warning = function()
  M.goto_warning(-1)
end

return M
