-- This module provides compiler functionality via overseer

local M = {}

local function get_current_compiler()
  if vim.w.srydell_compilers ~= nil and vim.w.srydell_compilers[vim.bo.filetype] ~= nil then
    local index = vim.w.srydell_compilers[vim.bo.filetype].index
    if index == nil then
      vim.print('No index')
      return nil
    end
    return vim.w.srydell_compilers[vim.bo.filetype].compilers[index]
  end

  -- Fetch the list of compilers for this filetype
  local status, compilers = pcall(require, 'srydell.compiler.filetype.' .. vim.bo.filetype)
  if not status then
    return nil
  end

  local new_filetype_compilers = vim.w.srydell_compilers or {}
  new_filetype_compilers[vim.bo.filetype] = { index = 1, compilers = compilers }

  vim.w.srydell_compilers = new_filetype_compilers
  -- NOTE: New compilers, index = 1
  return vim.w.srydell_compilers[vim.bo.filetype].compilers[1]
end

local function convert_to_overseer_orchestrator(tasks)
  -- The C bindings cannot convert the standard overseer orchestrator tables
  -- since they have tables both with keys and indices (e.g. { 'hi', 'ho' = 'he' })
  -- Overseer assumes that the first index is the task that follows by the options
  -- E.g.
  -- tasks = {
  --   {
  --     task = 'docker run',
  --     command = { '/Users/simryd/.config/nvim/tools/build_waf_target.sh' },
  --     with_option = true,
  --   },
  -- },
  -- out = {
  --   {
  --     'docker run',
  --     command = { '/Users/simryd/.config/nvim/tools/build_waf_target.sh' },
  --     with_option = true,
  --   },
  -- },
  -- tasks = { task = 'python run' },
  -- out = { 'python run' }
  local converted = {}
  for key, value in pairs(tasks) do
    if type(value) == 'table' then
      -- Nested table without keys
      if type(key) == 'number' then
        table.insert(converted, convert_to_overseer_orchestrator(value))
      else
        converted[key] = convert_to_overseer_orchestrator(value)
      end
    else
      -- Value is not a table
      if key == 'task' then
        table.insert(converted, 1, value)
      elseif key == 'edit_compiler_option' then
        -- Special keyword
        -- Remove it
        converted[key] = nil
      else
        converted[key] = value
      end
    end
  end
  return converted
end

-- Run a set of tasks from config via overseer
M.run = function()
  local compiler = get_current_compiler()
  if not compiler then
    vim.print('No current compiler')
    return
  end

  local overseer = require('overseer')
  local task = overseer.new_task({
    name = compiler.name,
    strategy = {
      'orchestrator',
      tasks = convert_to_overseer_orchestrator(compiler.tasks),
    },
  })
  task:start()
end

-- For display in e.g. status line
M.get_current_compiler_name = function()
  local compiler = get_current_compiler()
  if not compiler then
    return ''
  end

  return compiler.name
end

-- Moves the compiler index +1 or -1 depending on direction
-- number_of_compilers is for bounds checking
local function change_compiler(direction)
  local number_of_compilers = #vim.w.srydell_compilers[vim.bo.filetype].compilers

  local start_index = vim.w.srydell_compilers[vim.bo.filetype].index
  local new_index = start_index
  if direction == 1 then
    if start_index == number_of_compilers then
      new_index = 1
    elseif start_index < number_of_compilers then
      new_index = start_index + 1
    end
  elseif direction == -1 then
    if start_index == 1 then
      new_index = number_of_compilers
    elseif start_index > 1 then
      new_index = start_index - 1
    end
  end

  local new_compilers = vim.w.srydell_compilers
  new_compilers[vim.bo.filetype].index = new_index
  vim.w.srydell_compilers = new_compilers
end

M.go_to_next_compiler = function()
  if not get_current_compiler() then
    return nil
  end

  change_compiler(1)
end

M.go_to_previous_compiler = function()
  if not get_current_compiler() then
    return nil
  end

  change_compiler(-1)
end

M.replace_current_compiler = function(new_compiler)
  if new_compiler == nil then
    vim.print('New compiler is nil. Please return a valid compiler.')
    return nil
  end

  if new_compiler.name == nil or new_compiler.tasks == nil then
    vim.print('New compiler does not have "name". Please return a valid compiler.')
    return nil
  end

  if new_compiler.tasks == nil then
    vim.print('New compiler does not have "tasks". Please return a valid compiler.')
    return nil
  end

  local index = vim.w.srydell_compilers[vim.bo.filetype].index
  if index == nil then
    vim.print('No index. Internal error.')
    return nil
  end

  -- Set the new compiler
  local current = vim.w.srydell_compilers
  current[vim.bo.filetype].compilers[index] = new_compiler
  vim.w.srydell_compilers = current
end

M.edit_compiler_option = function()
  local compiler = get_current_compiler()
  if not compiler then
    vim.print('No compiler.')
    return nil
  end

  if compiler['edit_compiler_option'] ~= nil then
    compiler['edit_compiler_option'](compiler)
  end
end

return M
