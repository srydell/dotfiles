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

-- Internal function to make sure vim.bo.srydell_current_compiler has a value
-- and to get the compilers related to the current filetype
local function initiate_compilers()
  local status, compilers = pcall(require, 'srydell.compiler.filetype.' .. vim.bo.ft)
  if not status then
    return nil
  end

  if vim.b.srydell_current_compiler == nil then
    vim.b.srydell_current_compiler = 1
  end

  return compilers
end

M.get_current_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  if #compilers < vim.b.srydell_current_compiler then
    -- No compilers
    return nil
  end

  return compilers[vim.b.srydell_current_compiler]
end

M.go_to_next_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  local next = vim.b.srydell_current_compiler
  if next == #compilers then
    next = 1
  elseif next < #compilers then
    next = next + 1
  end

  vim.b.srydell_current_compiler = next
end

M.go_to_previous_compiler = function()
  local compilers = initiate_compilers()
  if not compilers then
    return nil
  end

  local previous = vim.b.srydell_current_compiler
  if previous == 1 then
    previous = #compilers
  elseif previous > 1 then
    previous = previous - 1
  end

  vim.b.srydell_current_compiler = previous
end

return M
