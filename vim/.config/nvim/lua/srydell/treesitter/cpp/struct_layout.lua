-- Find the struct/class/union enclosing the cursor and build its fully
-- qualified name (walking outward through nested classes and namespaces),
-- for srydell.util.struct_layout to feed into a `sizeof(...)`/`pahole -C`
-- lookup.
local navigation = require('srydell.treesitter.navigation')

local M = {}

local RECORD_TYPES = {
  struct_specifier = 'struct',
  class_specifier = 'class',
  union_specifier = 'union',
}

local function is_record(node)
  return RECORD_TYPES[node:type()] ~= nil
end

local function is_namespace(node)
  return node:type() == 'namespace_definition'
end

local function is_template(node)
  return node:type() == 'template_declaration'
end

local function get_field_text(node, field_name, buffer)
  local field = node:field(field_name)[1]
  if field == nil then
    return nil
  end
  return navigation.get_node_text(field, buffer)
end

-- Look for the struct/class/union under the cursor and build its fully
-- qualified name, e.g. `ns::Outer::Inner`.
-- Returns nil if the cursor isn't inside a record, or the record (or any
-- enclosing one) is anonymous or a template that hasn't been instantiated
-- (sizeof() can't be used directly on those).
-- On success, returns a table:
--   { name = 'ns::Outer::Inner', kind = 'struct'|'class'|'union', node = <innermost record node> }
M.get_qualified_name_under_cursor = function(buffer)
  buffer = buffer or 0
  local cursor_node = navigation.get_node_at_cursor()
  if cursor_node == nil then
    return nil, 'No treesitter node found under the cursor.'
  end

  local innermost = navigation.search_up_until(cursor_node, is_record)
  if innermost == nil then
    return nil, 'The cursor is not inside a struct/class/union.'
  end
  local kind = RECORD_TYPES[innermost:type()]

  -- Walk outward, collecting enclosing record/namespace names, innermost
  -- last so we can build the qualified name in declaration order.
  local parts = {}
  local node = innermost
  while node do
    if is_record(node) then
      local name = get_field_text(node, 'name', buffer)
      if name == nil then
        return nil, 'Cannot look up the layout of an anonymous struct/class/union.'
      end
      table.insert(parts, 1, name)
    elseif is_namespace(node) then
      local name = get_field_text(node, 'name', buffer)
      if name ~= nil then
        table.insert(parts, 1, name)
      end
    elseif is_template(node) then
      return nil, 'Cannot look up the layout of an uninstantiated template; pick a concrete instantiation instead.'
    end
    node = node:parent()
  end

  if #parts == 0 then
    return nil, 'Cannot look up the layout of an anonymous struct/class/union.'
  end

  return { name = table.concat(parts, '::'), kind = kind, node = innermost }
end

return M
