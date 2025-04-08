local M = {}

-- Compiler options is a complement to the compiler module
-- It stores state in vim.g.srydell_compiler_option with e.g.
-- {
--   gcc = {
--     value = 'debug',
--     generator = toggle_debug,
--   },
-- }
-- Any compiler template in lua/overseer/template/srydell/
-- can use these functions to change their behavior
-- NOTE: The global state vim.g.srydell_compiler_option
--       should **not** be touched directly outside this file

-- Make sure it exists
if vim.g.srydell_compiler_option == nil then
  vim.g.srydell_compiler_option = {}
end

local function get_key()
  return require('srydell.compiler.common').get_current_compiler_name()
end

local function initiate_option(value, generator, key)
  value = value or ''
  key = key or get_key()
  generator = generator or function()
    vim.print('No option for compiler: [' .. key .. ']')
  end
  local options = vim.g.srydell_compiler_option
  options[key] = { value = value, generator = generator }
  vim.g.srydell_compiler_option = options
end

M.get_compiler_option = function()
  local option = vim.g.srydell_compiler_option[get_key()]
  if option == nil then
    initiate_option()
    return ''
  end

  return option.value
end

M.edit_compiler_option = function()
  local key = get_key()
  local option = vim.g.srydell_compiler_option[key]
  if option == nil then
    initiate_option()
    option = vim.g.srydell_compiler_option[key]
  end

  option.generator()
  return M.get_compiler_option()
end

M.set_compiler_option = function(value, key)
  key = key or get_key()
  local options = vim.g.srydell_compiler_option
  local option = options[key]
  if option == nil then
    initiate_option(value)
    option = vim.g.srydell_compiler_option[key]
  end
  option.value = value
  options[key] = option
  vim.g.srydell_compiler_option = options
end

-- function options: {}
-- function option: nil
-- function#if option: nil
M.set_compiler_option_generator = function(generator, key)
  key = key or get_key()
  local options = vim.g.srydell_compiler_option
  local option = options[key]
  if option == nil then
    initiate_option('', generator, key)
    option = vim.g.srydell_compiler_option[key]
  end
  option.generator = generator
  options[key] = option
  vim.g.srydell_compiler_option = options
end

return M
