-- "Make atomic" refactoring helpers: turning plain variables/types into
-- std::atomic<T> and their assignments/increments into the matching
-- store/fetch_add/fetch_sub/load calls.
local navigation = require('srydell.treesitter.navigation')

local M = {}

-- variable = 54 -> variable.store(54, std::memory_order_release)
M.make_atomic_store = function()
  local function is_assignment(node)
    return node:type() == 'assignment_expression'
  end

  local function is_increment(node)
    -- E.g. ++ or --
    return node:type() == 'update_expression'
  end

  local curr_node = navigation.get_node_at_cursor()
  while curr_node do
    if is_assignment(curr_node) then
      -- E.g. a += 5;
      local assignment = {}
      for child, name in curr_node:iter_children() do
        assignment[name] = child
      end

      -- Early exit
      if assignment.left == nil or assignment.operator == nil or assignment.right == nil then
        return
      end

      local operator = navigation.get_node_text(assignment.operator)
      local left = navigation.get_node_text(assignment.left)
      local right = navigation.get_node_text(assignment.right)
      if operator == '=' then
        navigation.replace_node_with(curr_node, left .. '.store(' .. right .. ', std::memory_order_release)')
      elseif operator == '+=' then
        navigation.replace_node_with(curr_node, left .. '.fetch_add(' .. right .. ', std::memory_order_acq_rel)')
      elseif operator == '-=' then
        navigation.replace_node_with(curr_node, left .. '.fetch_sub(' .. right .. ', std::memory_order_acq_rel)')
      end

      return
    elseif is_increment(curr_node) then
      -- E.g. a++;
      local increment = {}
      for child, name in curr_node:iter_children() do
        increment[name] = child
      end
      if increment.argument == nil or increment.operator == nil then
        return
      end

      local argument = navigation.get_node_text(increment.argument)
      local operator = navigation.get_node_text(increment.operator)
      if operator == '++' then
        navigation.replace_node_with(curr_node, argument .. '.fetch_add(1, std::memory_order_acq_rel)')
      elseif operator == '--' then
        navigation.replace_node_with(curr_node, argument .. '.fetch_sub(1, std::memory_order_acq_rel)')
      end

      return
    end

    -- Go up in the stack
    curr_node = curr_node:parent()
  end
end

-- variable -> variable.load(std::memory_order_acquire)
M.make_atomic_load = function()
  local function is_variable(node)
    -- Simple variable
    -- or
    -- accessed variable (i.e. Data->var)
    return node:type() == 'identifier' or node:type() == 'field_identifier'
  end

  local function is_variable_or_parameter(node)
    -- Also trigger anywhere within a function parameter (e.g. cursor on its
    -- type), so we still need to drill down to the actual identifier below.
    return is_variable(node) or node:type() == 'parameter_declaration'
  end

  local node = navigation.search_up_until(navigation.get_node_at_cursor(), is_variable_or_parameter)
  if node == nil then
    return
  end

  local variable = node
  if node:type() == 'parameter_declaration' then
    -- Only wrap the identifier itself, not the whole 'Type name' declaration,
    -- otherwise e.g. 'int value' becomes the invalid 'int value.load(...)'.
    variable = navigation.search_down_until(node, is_variable)
    if variable == nil then
      return
    end
  end

  navigation.wrap_node_in('', variable, '.load(std::memory_order_acquire)')
end

-- Make the type under the cursor atomic. I.e.
-- int -> std::atomic<int>
-- If the node under the cursor is not a type, do nothing
M.make_atomic = function()
  local function is_type(node)
    return node:type() == 'primitive_type' or node:type() == 'type_identifier'
  end

  local type = navigation.search_up_until(navigation.get_node_at_cursor(), is_type)
  if type == nil then
    return
  end

  navigation.wrap_node_in('std::atomic<', type, '>')
end

return M
