-- C++ grammar node-type predicates, plus the small cursor-relative lookups
-- built directly on top of them. These describe *what a node is*; see
-- lua/srydell/treesitter/cpp/class_info.lua, function_signature.lua etc. for
-- helpers that extract information out of such nodes.
local navigation = require('srydell.treesitter.navigation')

local M = {}

M.is_identifier = function(node)
  return node:type() == 'identifier'
end

M.is_parameters = function(node)
  return node:type() == 'parameter_list'
end

M.is_parameter = function(node)
  return node:type() == 'parameter_declaration' or node:type() == 'optional_parameter_declaration'
end

M.is_function = function(node)
  return node:type() == 'function_declarator'
end

M.is_class_or_struct = function(node)
  return node:type() == 'class_specifier' or node:type() == 'struct_specifier'
end

M.is_function_name = function(node)
  return node:type() == 'identifier' -- Simple free function
    or node:type() == 'field_identifier' -- Class function
    or node:type() == 'qualified_identifier' -- Function with namespace qualifier
    or node:type() == 'destructor_name' -- Destructor
    or node:type() == 'operator_name' -- Operator
end

-- Assumes the input function_node is function_node:type() == 'function_declarator'
M.is_function_implementation = function(function_node)
  local function is_implementation(node)
    -- Implemented function
    return node:type() == 'function_definition'
  end

  local implementation = navigation.search_up_until(function_node, is_implementation)
  return implementation ~= nil
end

-- Check wether the node under the cursor is within a parameter list or not.
-- If it is, return the parameter list node.
M.get_surrounding_argument_list = function()
  local node_at_cursor = navigation.get_node_at_cursor()
  if node_at_cursor == nil then
    return
  end

  local function is_argument(node)
    return node:type() == 'argument_list'
  end
  return navigation.search_up_until(node_at_cursor, is_argument)
end

-- Check wether the node under the cursor is within a function or not.
-- If it is, return the function node.
M.get_surrounding_function = function()
  local node_at_cursor = navigation.get_node_at_cursor()
  if node_at_cursor == nil then
    return
  end

  local function in_function(node)
    return node:type() == 'function_definition'
  end
  return navigation.search_up_until(node_at_cursor, in_function)
end

return M
