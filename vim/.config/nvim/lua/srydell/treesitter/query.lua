local M = {}

-- Look up in the scope from the cursor until node_type is found
M.get_parent_node_from_cursor = function(node_type)
  local ts_utils = require('nvim-treesitter.ts_utils')
  local ts_locals = require('nvim-treesitter.locals')

  local curr_node = ts_utils.get_node_at_cursor()
  if curr_node == nil then
    return nil
  end

  -- NOTE: 0 is the current buffer
  local scope = ts_locals.get_scope_tree(curr_node, 0)

  for _, node in ipairs(scope) do
    if node:type() == node_type then
      return node
    end
  end
  return nil
end

-- Helper function for C++
local function remove_reference_or_pointers(type)
  if #type <= 1 then
    return type
  end

  local first_char = type:sub(1, 1)
  if first_char == '*' or first_char == '&' then
    return type:sub(2)
  end
  return type
end

-- Return some information about the function in the scope of the cursor
M.get_function_info = function()
  local function_node = M.get_parent_node_from_cursor('function_definition')
  if not function_node then
    return
  end

  local return_node = function_node:field('type')
  local decl_node = function_node:field('declarator')
  local name_node = decl_node[1]:field('declarator')
  local parameter_nodes = decl_node[1]:field('parameters')

  local parameters = {}
  for param in parameter_nodes[1]:iter_children() do
    if param:type() == 'parameter_declaration' then
      -- The name might have reference or pointers attached
      local param_name = vim.treesitter.get_node_text(param:field('declarator')[1], 0)
      table.insert(parameters, {
        type = vim.treesitter.get_node_text(param:field('type')[1], 0),
        name = remove_reference_or_pointers(param_name),
      })
    end
  end

  return {
    return_type = vim.treesitter.get_node_text(return_node[1], 0),
    name = vim.treesitter.get_node_text(name_node[1], 0),
    parameters = parameters,
    start_line = function_node:start(),
  }
end

-- Return some information about the class in the scope of the cursor
M.get_class_info = function()
  local class_node = M.get_parent_node_from_cursor('class_specifier')
    or M.get_parent_node_from_cursor('struct_specifier')
  if not class_node then
    return
  end

  local name_node = class_node:field('name')

  return {
    name = vim.treesitter.get_node_text(name_node[1], 0),
    start_line = class_node:start(),
  }
end

return M
