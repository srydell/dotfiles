-- Generators for boilerplate "rule of 5" class members: deleted move/copy
-- constructors and assignment operators.
local class_info = require('srydell.treesitter.cpp.class_info')

local M = {}

-- If there is a class where the cursor is:
-- Create deleted move constructors
M.make_class_no_move = function()
  local name = class_info.get_class_name_under_cursor()
  if name == nil then
    return
  end

  local indentation = class_info.get_indentation()

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local no_move = {
    string.format('%s// No move', indentation),
    -- noexcept by default: lets std containers (e.g. std::vector) move
    -- instead of copy on reallocation.
    string.format('%s%s(%s &&) noexcept = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s &&) noexcept = delete;', indentation, name, name),
  }

  vim.api.nvim_buf_set_lines(0, row, row, true, no_move)
end

-- If there is a class where the cursor is:
-- Create deleted copy constructors
M.make_class_no_copy = function()
  local name = class_info.get_class_name_under_cursor()
  if name == nil then
    return
  end

  local indentation = class_info.get_indentation()

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local no_copy = {
    string.format('%s// No copy', indentation),
    string.format('%s%s(%s const &) = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s const &) = delete;', indentation, name, name),
  }

  vim.api.nvim_buf_set_lines(0, row, row, true, no_copy)
end

return M
