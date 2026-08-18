-- Lookups for the class/struct a treesitter node or the cursor is inside of,
-- plus a small formatting helper (get_indentation) shared by the class-member
-- generators in class_members.lua and definitions.lua.
local navigation = require('srydell.treesitter.navigation')
local predicates = require('srydell.treesitter.cpp.predicates')

local M = {}

M.get_class_name = function(class_node, buffer)
  buffer = buffer or 0
  for child, name in class_node:iter_children() do
    if name == 'name' then
      return navigation.get_node_text(child, buffer)
    end
  end
end

-- Look for a class under the cursor.
-- Return the name as a string
M.get_class_name_under_cursor = function()
  local class_node = navigation.search_up_until(navigation.get_node_at_cursor(), predicates.is_class_or_struct)
  if class_node == nil then
    return
  end

  return M.get_class_name(class_node)
end

-- Look at the line where the cursor is.
-- Return the indentation of that line as a string.
M.get_indentation = function()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  -- Go up 10 lines to try and get a line containing indentation
  local lines = vim.api.nvim_buf_get_lines(0, math.max(row - 11, 0), row, false)
  for i = #lines, 1, -1 do
    local indentation, _ = lines[i]:match('^(%s*)(.*)')
    if indentation ~= '' then
      return indentation
    end
  end
  return ''
end

return M
