-- This module provides compiler functionality via overseer

local M = {}

-- Run a set of tasks from config via overseer
M.run = function()
  local compiler = M.get_current_compiler()
  if not compiler then
    vim.print('No current compiler')
    return
  end

  local overseer = require('overseer')
  local task = overseer.new_task({
    name = compiler.name,
    strategy = {
      'orchestrator',
      tasks = compiler.tasks,
    },
  })
  task:start()
end

-- Internal function to make sure vim.w.srydell_current_compiler has a value
-- and to get the compilers related to the current filetype
local function initiate_compilers()
  -- Fetch the list of compilers for this filetype
  local status, compilers = pcall(require, 'srydell.compiler.filetype.' .. vim.bo.filetype)
  if not status then
    return nil
  end

  -- Make sure that the compiler index exists for this filetype
  if vim.w.srydell_current_compiler == nil then
    -- First time opening vim
    local c = {}
    c[vim.bo.filetype] = 1
    vim.w.srydell_current_compiler = c
  elseif vim.w.srydell_current_compiler[vim.bo.filetype] == nil then
    -- Opening a new filetype
    local c = vim.w.srydell_current_compiler
    c[vim.bo.filetype] = 1
    vim.w.srydell_current_compiler = c
  end

  return compilers
end

M.get_current_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  local index = vim.w.srydell_current_compiler[vim.bo.filetype]
  if #compilers < index then
    -- No compilers
    return nil
  end

  return compilers[index]
end

-- Moves the compiler index +1 or -1 depending on direction
-- number_of_compilers is for bounds checking
local function change_compiler(direction, number_of_compilers)
  local index = vim.w.srydell_current_compiler[vim.bo.filetype]
  if direction == 1 then
    if index == number_of_compilers then
      index = 1
    elseif index < number_of_compilers then
      index = index + 1
    end
  elseif direction == -1 then
    if index == 1 then
      index = number_of_compilers
    elseif index > 1 then
      index = index - 1
    end
  end

  local new_compilers = vim.w.srydell_current_compiler
  new_compilers[vim.bo.filetype] = index
  vim.w.srydell_current_compiler = new_compilers
end

M.go_to_next_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  change_compiler(1, #compilers)
end

M.go_to_previous_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  change_compiler(-1, #compilers)
end

return M
