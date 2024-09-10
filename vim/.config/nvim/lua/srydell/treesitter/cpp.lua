local M = {}

local function get_node_text(node, buffer)
  buffer = buffer or 0
  return vim.treesitter.get_node_text(node, buffer)
end

-- Go up the treesitter tree until stop condition is met
local function search_up_until(node, stop_condition)
  if node == nil then
    return
  end

  while node do
    if stop_condition(node) then
      return node
    end

    node = node:parent()
  end
end

-- Go down the treesitter tree until stop condition is met
-- Visit the nodes in breadth first
local function search_down_until(node, stop_condition)
  if node == nil then
    return
  end

  local nodes = { node }

  while node and not vim.tbl_isempty(nodes) do
    node = table.remove(nodes, 1)

    if stop_condition(node) then
      return node
    end

    for child, _ in node:iter_children() do
      if node ~= nil then
        table.insert(nodes, child)
      end
    end
  end
end

-- Wrap a treesitter node on the current line in text as
-- node_text -> before .. node_text .. after
-- This assumes that the node is on the current line of the cursor
local function wrap_node_in(node, before, after)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  local to_be_wrapped = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. before .. to_be_wrapped .. after .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  vim.api.nvim_win_set_cursor(0, { row, col + before:len() })
end

local function replace_node_with(node, text)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  local to_be_removed = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. text .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  -- vim.api.nvim_win_set_cursor(0, { row, col + (text:len() - to_be_removed:len()) })
end

local function add_text_after(node, text, offset)
  offset = offset or 0
  local _, _, end_node_row, _ = vim.treesitter.get_node_range(node)

  local lines = {}
  for line in text:gmatch('[^\n]+') do
    table.insert(lines, line)
  end

  -- Replace the current line with the wrapped text
  vim.api.nvim_buf_set_lines(0, end_node_row + 1 + offset, end_node_row + 1 + offset, true, lines)
end

-- variable = 54 -> variable.store(54, std::memory_order_release)
function M.make_atomic_store()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_assignment(node)
    return node:type() == 'assignment_expression'
  end

  local function is_increment(node)
    -- E.g. ++ or --
    return node:type() == 'update_expression'
  end

  local curr_node = ts_utils.get_node_at_cursor()
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

      local operator = get_node_text(assignment.operator)
      local left = get_node_text(assignment.left)
      local right = get_node_text(assignment.right)
      if operator == '=' then
        replace_node_with(curr_node, left .. '.store(' .. right .. ', std::memory_order_release)')
      elseif operator == '+=' then
        replace_node_with(curr_node, left .. '.fetch_add(' .. right .. ', std::memory_order_acq_rel)')
      elseif operator == '-=' then
        replace_node_with(curr_node, left .. '.fetch_sub(' .. right .. ', std::memory_order_acq_rel)')
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

      local argument = get_node_text(increment.argument)
      local operator = get_node_text(increment.operator)
      if operator == '++' then
        replace_node_with(curr_node, argument .. '.fetch_add(1, std::memory_order_acq_rel)')
      elseif operator == '--' then
        replace_node_with(curr_node, argument .. '.fetch_sub(1, std::memory_order_acq_rel)')
      end

      return
    end

    -- Go up in the stack
    curr_node = curr_node:parent()
  end
end

-- variable -> variable.load(std::memory_order_acquire)
function M.make_atomic_load()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_variable(node)
    -- Simple variable
    -- or
    -- accessed variable (i.e. Data->var)
    -- or
    -- variable in function argument list
    return node:type() == 'identifier' or node:type() == 'field_identifier' or node:type() == 'parameter_declaration'
  end

  local variable = search_up_until(ts_utils.get_node_at_cursor(), is_variable)
  if variable == nil then
    return
  end
  wrap_node_in(variable, '', '.load(std::memory_order_acquire)')
end

-- Make the type under the cursor atomic. I.e.
-- int -> std::atomic<int>
-- If the node under the cursor is not a type, do nothing
function M.make_atomic()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_type(node)
    return node:type() == 'primitive_type' or node:type() == 'type_identifier'
  end

  local type = search_up_until(ts_utils.get_node_at_cursor(), is_type)
  if type == nil then
    return
  end

  wrap_node_in(type, 'std::atomic<', '>')
end

local function is_enum(node)
  return node:type() == 'enum_specifier'
end

local function parse_enum(enum_node, buffer)
  buffer = buffer or 0
  local enum = {}
  for child, name in enum_node:iter_children() do
    if name == 'name' then
      enum[name] = get_node_text(child, buffer)
    elseif name == 'body' then
      enum['values'] = {}
      for enumerator, _ in child:iter_children() do
        for value, value_name in enumerator:iter_children() do
          if value_name == 'name' then
            table.insert(enum['values'], get_node_text(value, buffer))
          end
        end
      end
    end
  end
  return enum
end

local function get_enum_under_cursor()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local enum_node = search_up_until(ts_utils.get_node_at_cursor(), is_enum)
  if enum_node == nil then
    return
  end

  local enum = parse_enum(enum_node)

  -- Early exit
  if enum.name == nil or enum.values == nil then
    return nil, nil
  end

  return enum, enum_node
end

function M.make_enum_print()
  local enum, node = get_enum_under_cursor()

  if enum == nil or node == nil then
    return
  end

  if enum.name == nil or enum.values == nil then
    return
  end

  local cases = {}
  for _, value in ipairs(enum.values) do
    table.insert(
      cases,
      string.format(
        [[  case %s::%s: {
    std::cout << "%s::%s" << '\n';
  }]],
        enum.name,
        value,
        enum.name,
        value
      )
    )
  end

  local enum_printer_function = string.format(
    [[
void print(%s e) {
  switch (e) {
%s
  }
  std::cout << "Unknown enum from %s" << '\n';
}
]],
    enum.name,
    table.concat(cases, '\n'),
    enum.name
  )

  add_text_after(node, enum_printer_function)
end

function M.make_enum_stringify()
  local enum, node = get_enum_under_cursor()

  if enum == nil or node == nil then
    return
  end

  if enum.name == nil or enum.values == nil then
    return
  end

  local cases = {}
  for _, value in ipairs(enum.values) do
    table.insert(
      cases,
      string.format(
        [[  case %s::%s: {
    return "%s::%s";
  }]],
        enum.name,
        value,
        enum.name,
        value
      )
    )
  end

  local enum_stringify_function = string.format(
    [[
std::string to_string(%s e) {
  switch (e) {
%s
  }
  return "Unknown";
}
]],
    enum.name,
    table.concat(cases, '\n')
  )

  add_text_after(node, enum_stringify_function)
end

function M.make_enum_binary()
  local enum, node = get_enum_under_cursor()

  if enum == nil or node == nil then
    return
  end

  if enum.name == nil or enum.values == nil then
    return
  end

  local cases = {}
  for _, value in ipairs(enum.values) do
    table.insert(
      cases,
      string.format(
        [[  if ((event & %s::%s) > 0) {
    return "%s::%s";
  }]],
        enum.name,
        value,
        enum.name,
        value
      )
    )
  end

  local enum_binary_stringify = string.format(
    [[
std::string to_string(uint32_t event) {
%s
  return "Unknown";
}
]],
    table.concat(cases, '\n')
  )

  add_text_after(node, enum_binary_stringify)
end

function M.make_enum_switch()
  local enum, node = get_enum_under_cursor()

  if enum == nil or node == nil then
    return
  end

  if enum.name == nil or enum.values == nil then
    return
  end

  local cases = {}
  for _, value in ipairs(enum.values) do
    table.insert(
      cases,
      string.format(
        [[  case %s::%s: {
    return;
  }]],
        enum.name,
        value,
        enum.name,
        value
      )
    )
  end

  local enum_switch = string.format(
    [[
  switch (e) {
%s
  }
]],
    table.concat(cases, '\n')
  )

  add_text_after(node, enum_switch)
end

local function get_type_info_under_cursor()
  local type_definition =
    vim.lsp.buf_request_sync(0, 'textDocument/typeDefinition', vim.lsp.util.make_position_params(), 1000)
  if not type_definition or vim.tbl_isempty(type_definition) then
    return
  end

  for _, lsp_data in pairs(type_definition) do
    if lsp_data ~= nil and lsp_data.result ~= nil and not vim.tbl_isempty(lsp_data.result) then
      for _, value in pairs(lsp_data.result) do
        local range = value.range or value.targetRange
        if range ~= nil then
          local file = value.uri or value.targetUri
          -- skip node module
          -- if file ~=nil and not string.match(file,'node_modules') then
          if file ~= nil then
            -- mark current cursor open to jumplist
            local line = range.start.line
            file = file:gsub('file://', '')
            return {
              file = file,
              line = line,
              start_char = range.start.character,
              end_char = range['end'].character,
            }
          end
        end
      end
    end
  end

  return nil
end

function M.find_enum_from_type()
  local type_info = get_type_info_under_cursor()
  if type_info == nil then
    return
  end

  -- Load the buffer that contains the source enum
  local buffer = vim.fn.bufadd(type_info.file)
  vim.fn.bufload(buffer)

  -- Get the lines containing the enum declaration. E.g.
  -- 'enum class MyEnum {'
  local lines = vim.api.nvim_buf_get_lines(buffer, type_info.line, type_info.line + 1, false)

  -- Get the name. E.g.
  -- 'MyEnum'
  local type_name = lines[1]:sub(type_info.start_char + 1, type_info.end_char)

  local is_our_enum = function(node)
    if is_enum(node) then
      local text = vim.treesitter.get_node_text(node, buffer)
      if text == nil then
        return false
      end

      return text:find(type_name) ~= nil
    end
    return false
  end

  local trees = vim.treesitter.get_parser(buffer, 'cpp'):parse()
  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root == nil then
      return
    end

    local enum_node = search_down_until(tree:root(), is_our_enum)
    if enum_node == nil then
      return
    end
    return parse_enum(enum_node, buffer)
  end
end

return M
