-- This module provides compiler functionality via overseer

local M = {}

local function get_context()
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = vim.fn.getcwd()
  local project = require('srydell.util').get_project()
  local filetype = vim.bo.filetype
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    cwd = cwd,
    file = file,
    filetype = filetype,
    key = table.concat({ filetype, cwd, file }, ':'),
    project = project,
  }
end

local function get_state(ctx)
  local states = vim.w.srydell_compilers or {}
  local state = states[ctx.key]
  if state == nil then
    state = { index = 1 }
    states[ctx.key] = state
    vim.w.srydell_compilers = states
  end
  return state
end

local function save_state(ctx, state)
  local states = vim.w.srydell_compilers or {}
  states[ctx.key] = state
  vim.w.srydell_compilers = states
end

local function notify_loader_error(module, err)
  local missing_module = string.find(err, "module '" .. module .. "' not found", 1, true) ~= nil
  if not missing_module then
    vim.notify('Failed to load compiler module ' .. module .. ':\n' .. err, vim.log.levels.ERROR)
  end
end

local function load_compilers(ctx)
  local module = 'srydell.compiler.filetype.' .. ctx.filetype
  local status, resolver = pcall(require, module)
  if not status then
    notify_loader_error(module, resolver)
    return {}
  end

  local compilers = resolver
  if type(resolver) == 'function' then
    local ok, result = pcall(resolver, ctx)
    if not ok then
      vim.notify('Failed to resolve compilers for ' .. ctx.filetype .. ':\n' .. result, vim.log.levels.ERROR)
      return {}
    end
    compilers = result
  end

  if compilers == nil then
    return {}
  end

  if type(compilers) ~= 'table' then
    vim.notify('Compiler module ' .. module .. ' must return a table or resolver function.', vim.log.levels.ERROR)
    return {}
  end

  return compilers
end

local function get_current_compiler()
  local ctx = get_context()
  local state = get_state(ctx)
  local compilers = state.compilers or load_compilers(ctx)
  state.compilers = compilers

  if #compilers == 0 then
    return nil
  end

  if state.index == nil or state.index > #compilers then
    state.index = 1
  end
  save_state(ctx, state)
  return compilers[state.index]
end

local function convert_task_to_overseer(task)
  if type(task) ~= 'table' then
    return task
  end

  local converted = {}
  if task.task ~= nil then
    table.insert(converted, task.task)
  end

  for _, value in ipairs(task) do
    if type(value) == 'table' then
      table.insert(converted, convert_task_to_overseer(value))
    else
      table.insert(converted, value)
    end
  end

  for key, value in pairs(task) do
    if type(key) ~= 'number' and key ~= 'task' then
      if type(value) == 'table' then
        converted[key] = convert_task_to_overseer(value)
      else
        converted[key] = value
      end
    end
  end

  return converted
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
  if tasks.task ~= nil then
    return convert_task_to_overseer(tasks)
  end

  local converted = {}
  for _, task in ipairs(tasks) do
    table.insert(converted, convert_task_to_overseer(task))
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

  -- Cancel running tasks
  local overseer = require('overseer')
  for _, task in ipairs(overseer.list_tasks({ status = 'RUNNING' })) do
    task:stop()
  end

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
  local ctx = get_context()
  local state = get_state(ctx)
  local compilers = state.compilers or load_compilers(ctx)
  state.compilers = compilers
  local number_of_compilers = #compilers
  if number_of_compilers == 0 then
    return
  end

  local start_index = state.index or 1
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

  state.index = new_index
  save_state(ctx, state)
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

  if new_compiler.name == nil then
    vim.print('New compiler does not have "name". Please return a valid compiler.')
    return nil
  end

  if new_compiler.tasks == nil then
    vim.print('New compiler does not have "tasks". Please return a valid compiler.')
    return nil
  end

  local ctx = get_context()
  local state = get_state(ctx)
  local index = state.index
  if index == nil then
    vim.print('No index. Internal error.')
    return nil
  end

  -- Set the new compiler
  state.compilers = state.compilers or load_compilers(ctx)
  state.compilers[index] = new_compiler
  save_state(ctx, state)
end

M.edit_compiler_option = function()
  local compiler = get_current_compiler()
  if not compiler then
    vim.print('No compiler.')
    return nil
  end

  if compiler['edit_compiler_option'] ~= nil then
    local new_compiler = compiler['edit_compiler_option'](vim.deepcopy(compiler))
    if new_compiler ~= nil then
      M.replace_current_compiler(new_compiler)
    end
  end
end

M.edit_current_compiler = function()
  local compiler = get_current_compiler()
  if not compiler then
    vim.print('No compiler.')
    return nil
  end

  local file = ''
  if compiler['tasks'] ~= nil then
    if compiler['tasks']['task'] ~= nil then
      file = compiler['tasks']['task']
    elseif compiler['tasks'][1] ~= nil and compiler['tasks'][1]['task'] then
      file = compiler['tasks'][1]['task']
    end
  end

  if file == '' then
    vim.print('No file to edit.')
    return nil
  end

  -- Replace spaces with underscores
  file = file:gsub(' ', '_')

  file = vim.fn.stdpath('config') .. '/lua/overseer/template/srydell/' .. file .. '.lua'
  if vim.fn.filereadable(file) == 1 then
    vim.cmd('edit ' .. file)
  else
    vim.print('File ' .. file .. ' is not readable.')
  end
end

return M
