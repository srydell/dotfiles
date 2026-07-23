local M = {}

M.get_node_text = function(node, buffer)
  buffer = buffer or 0
  return vim.treesitter.get_node_text(node, buffer)
end

M.get_row = function(node)
  local row, _, _, _ = vim.treesitter.get_node_range(node)
  return row
end

-- Go up the treesitter tree until stop condition is met.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_up_until = function(node, stop_condition)
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

-- Go down the treesitter tree from node until stop condition is met.
-- Visit the nodes in breadth first.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_down_until = function(node, stop_condition)
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
      table.insert(nodes, child)
    end
  end
end

-- Parse the buffer content and search down from the root
-- until a stop condition is met or there are no more nodes.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_down_from_root_until = function(stop_condition, buffer)
  buffer = buffer or 0
  local ok, parser = pcall(vim.treesitter.get_parser, buffer, 'cpp')
  if not ok or not parser then
    return
  end

  local trees = parser:parse()
  if not trees then
    return
  end
  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root == nil then
      return
    end

    local end_node = M.search_down_until(tree:root(), stop_condition)
    if end_node then
      return end_node
    end
  end
end

-- Wrap a treesitter node on the current line in text as
-- node_text -> before .. node_text .. after
-- This assumes that the node is on the current line of the cursor
local function wrap_node_in(before, node, after)
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

-- Takes the text that the node is currently containing and
-- replaces it with text in the current buffer.
local function replace_node_with(node, text)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  -- local to_be_removed = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. text .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  -- vim.api.nvim_win_set_cursor(0, { row, col + (text:len() - to_be_removed:len()) })
end

-- Add text after the end of the node.
-- Can add an extra padding of rows (offset).
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

-- A version that reparses the tree
-- Useful when you're trying to act on something that you have not saved yet.
-- Use when not caring about performance
local function get_node_at_cursor(winnr)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, 'cpp')
  if not ok or not parser then
    return nil
  end

  local trees = parser:parse()
  if not trees then
    return nil
  end

  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root then
      return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
    end
  end

  return nil
end

-- A set of is_* functions to be used when searching for nodes.

local function is_identifier(node)
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

  local implementation = M.search_up_until(function_node, is_implementation)
  return implementation ~= nil
end

-- Check wether the node under the cursor is within a parameter list or not.
-- If it is, return the parameter list node.
M.get_surrounding_argument_list = function()
  local node_at_cursor = get_node_at_cursor()
  if node_at_cursor == nil then
    return
  end

  local function is_argument(node)
    return node:type() == 'argument_list'
  end
  return M.search_up_until(node_at_cursor, is_argument)
end

-- Check wether the node under the cursor is within a function or not.
-- If it is, return the function node.
M.get_surrounding_function = function()
  local node_at_cursor = get_node_at_cursor()
  if node_at_cursor == nil then
    return
  end

  local function in_function(node)
    return node:type() == 'function_definition'
  end
  return M.search_up_until(node_at_cursor, in_function)
end

-- Removes the name and the default parameter values from the parameters.
-- Also removes whitespace to make it easier to compare parameters as strings.
-- I.e. (std::string my_string, int i = 5) -> (std::string,int)
local function clean_params(params_node, buffer)
  buffer = buffer or 0
  local params = '('
  local function concatenate_params(node)
    -- Simple parameter or with a default value
    if M.is_parameter(node) then
      -- The whole parameter - e.g. 'std::string const & s = "hi"'
      local name = M.search_down_until(node, is_identifier)
      if name ~= nil then
        local start_row, start_col, _, _ = vim.treesitter.get_node_range(node)
        local _, start_name_col, end_row, _ = vim.treesitter.get_node_range(name)
        -- Remove anything after the name
        -- This includes default parmeters
        local parameter = vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, start_name_col, {})
        params = params .. parameter[1] .. ','
      else
        -- No name parameter
        if node:type() == 'parameter_declaration' then
          -- Take the whole param name
          params = params .. M.get_node_text(node, buffer) .. ','
        else
          -- Optional parameter with no name? Yikes.
          -- Remove anything after the '='
          local param_name = M.get_node_text(node, buffer)
          param_name = param_name:sub(1, param_name:find('=') - 1)
          params = params .. param_name .. ','
        end
      end
    end
  end

  M.search_down_until(params_node, concatenate_params)
  -- Remove the last ','
  -- and close the parenthesis
  if params:sub(#params, #params) == ',' then
    params = params:sub(1, -2)
  end
  params = params .. ')'
  -- Remove the whitespace to make it possible to match against
  -- (you could have differently formatted params)
  params = params:gsub('%s+', '')
  return params
end

-- Return if the function is const etc.
-- Assumes function_node:type() == 'function_declarator'
-- E.g.
--   int f() const -> 'const'
local function get_function_qualifiers(function_node, buffer)
  local parameters_node = M.search_down_until(function_node, M.is_parameters)
  if parameters_node == nil then
    return ''
  end

  -- Everything after the parameter node to the end of the function node
  local _, _, end_row, end_col = vim.treesitter.get_node_range(function_node)
  local _, _, start_row, start_col = vim.treesitter.get_node_range(parameters_node)

  local qualifiers = vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col, {})[1]
  if qualifiers == nil then
    return ''
  end

  -- Remove leading & trailing whitespace
  qualifiers = qualifiers:gsub('^%s*', '')
  qualifiers = qualifiers:gsub('%s*$', '')
  return qualifiers
end

local function remove_declaration_only_qualifiers(qualifiers)
  -- Should not include things that are only in the declaration
  qualifiers = qualifiers:gsub('final', '')
  qualifiers = qualifiers:gsub('override', '')
  qualifiers = qualifiers:gsub('noexcept', '')
  qualifiers = qualifiers:gsub('explicit', '')

  -- Remove whitespace
  qualifiers = qualifiers:gsub('^%s*', '')
  qualifiers = qualifiers:gsub('%s*$', '')
  return qualifiers
end

local function get_function_qualifiers_for_snippet(function_node, buffer)
  local qualifiers = get_function_qualifiers(function_node, buffer)

  -- Should not include things that are only in the declaration
  qualifiers = remove_declaration_only_qualifiers(qualifiers)
  if qualifiers ~= '' then
    -- For simplicity in the snippet
    qualifiers = ' ' .. qualifiers
  end
  return qualifiers
end

local function get_return_type(function_node, buffer)
  local function_name_node = M.search_down_until(function_node, M.is_function_name)

  -- Give up
  if function_name_node == nil then
    return ''
  end

  local function is_function_root(node)
    return node:type() == 'declaration' or node:type() == 'field_declaration' or node:type() == 'function_definition'
  end

  local function_root = M.search_up_until(function_node, is_function_root)
  if function_root == nil then
    return ''
  end

  local start_row, start_col, _, _ = vim.treesitter.get_node_range(function_root)
  local _, start_name_col, end_row, _ = vim.treesitter.get_node_range(function_name_node)
  local return_type = vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, start_name_col, {})[1]
  return return_type:gsub('%s+$', '')
end

local function remove_declaration_only_return_qualifiers(return_type)
  -- Should not include things that are only in the declaration
  return_type = return_type:gsub('inline', '')
  return_type = return_type:gsub('static', '')
  return_type = return_type:gsub('virtual', '')
  -- This happens since dtor/ctor have no return type explicitly
  return_type = return_type:gsub('explicit', '')

  -- Remove whitespace
  return_type = return_type:gsub('^%s*', '')
  return_type = return_type:gsub('%s*$', '')
  return return_type
end

local function get_function_return_for_snippet(function_node, buffer)
  local return_type = get_return_type(function_node, buffer)

  -- Should not include things that are only in the declaration
  return_type = remove_declaration_only_return_qualifiers(return_type)
  if return_type ~= '' then
    -- For simplicity in the snippet
    return_type = return_type .. ' '
  end
  return return_type
end

-- function_node:type() == 'function_declarator'
-- buffer is optional integer defaults to 0 (current buffer)
local function get_compressed_function_name(function_node, buffer)
  buffer = buffer or 0

  local compressed_name = ''

  local class_node = M.search_up_until(function_node, M.is_class_or_struct)
  local class_prefix = ''
  if class_node ~= nil then
    class_prefix = M.get_class_name(class_node, buffer) .. '::'
  end

  for child, _ in function_node:iter_children() do
    -- Name of the function
    if M.is_function_name(child) then
      compressed_name = compressed_name .. class_prefix .. M.get_node_text(child, buffer)
    end

    if M.is_parameters(child) then
      compressed_name = compressed_name .. clean_params(child, buffer)
    end
  end

  -- Try to find the return value
  -- This is at the end as we need the start of the function name
  -- Note: For constructors/destructors this is ''
  local return_type = get_return_type(function_node, buffer)
  return_type = remove_declaration_only_return_qualifiers(return_type):gsub('%s+', '')
  if return_type ~= '' then
    compressed_name = return_type .. ' ' .. compressed_name
  end

  -- E.g. 'const' in 'int f() const'
  local qualifiers = get_function_qualifiers(function_node, buffer)
  qualifiers = remove_declaration_only_qualifiers(qualifiers):gsub('%s+', '')
  if qualifiers ~= '' then
    compressed_name = compressed_name .. ' ' .. qualifiers
  end

  return compressed_name
end

-- variable = 54 -> variable.store(54, std::memory_order_release)
function M.make_atomic_store()
  local function is_assignment(node)
    return node:type() == 'assignment_expression'
  end

  local function is_increment(node)
    -- E.g. ++ or --
    return node:type() == 'update_expression'
  end

  local curr_node = get_node_at_cursor()
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

      local operator = M.get_node_text(assignment.operator)
      local left = M.get_node_text(assignment.left)
      local right = M.get_node_text(assignment.right)
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

      local argument = M.get_node_text(increment.argument)
      local operator = M.get_node_text(increment.operator)
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
  local function is_variable(node)
    -- Simple variable
    -- or
    -- accessed variable (i.e. Data->var)
    -- or
    -- variable in function argument list
    return node:type() == 'identifier' or node:type() == 'field_identifier' or node:type() == 'parameter_declaration'
  end

  local variable = M.search_up_until(get_node_at_cursor(), is_variable)
  if variable == nil then
    return
  end
  wrap_node_in('', variable, '.load(std::memory_order_acquire)')
end

-- Make the type under the cursor atomic. I.e.
-- int -> std::atomic<int>
-- If the node under the cursor is not a type, do nothing
function M.make_atomic()
  local function is_type(node)
    return node:type() == 'primitive_type' or node:type() == 'type_identifier'
  end

  local type = M.search_up_until(get_node_at_cursor(), is_type)
  if type == nil then
    return
  end

  wrap_node_in('std::atomic<', type, '>')
end

local function is_enum(node)
  return node:type() == 'enum_specifier'
end

local function parse_enum(enum_node, buffer)
  buffer = buffer or 0
  local enum = {}
  for child, name in enum_node:iter_children() do
    if name == 'name' then
      enum[name] = M.get_node_text(child, buffer)
    elseif name == 'body' then
      enum['values'] = {}
      for enumerator, _ in child:iter_children() do
        for value, value_name in enumerator:iter_children() do
          if value_name == 'name' then
            table.insert(enum['values'], M.get_node_text(value, buffer))
          end
        end
      end
    end
  end
  return enum
end

local function get_enum_under_cursor()
  local enum_node = M.search_up_until(get_node_at_cursor(), is_enum)
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

-- Create a stringify enum switch function over all the cases based on the enum under the cursor
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

-- Create a binary enum switch function over all the cases based on the enum under the cursor
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

-- Create a simple enum switch over all the cases based on the enum under the cursor
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

-- Do a LSP typeDefinition check for the type under the cursor
-- Return a simplified version of the output
local function get_type_info_under_cursor()
  local type_definition =
    vim.lsp.buf_request_sync(0, 'textDocument/typeDefinition', vim.lsp.util.make_position_params(0, 'utf-8'), 1000)
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

-- Do a type check via LSP to find the enum that is under the cursor
-- Reads the file via treesitter that contains the enum.
function M.find_enum_from_type()
  local type_info = get_type_info_under_cursor()
  if type_info == nil then
    return
  end

  -- Load the buffer that contains the source enum
  local buffer = vim.fn.bufadd(type_info.file)
  if not vim.fn.bufloaded(buffer) then
    vim.fn.bufload(buffer)
  end

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

  local enum_node = M.search_down_from_root_until(is_our_enum, buffer)
  if enum_node == nil then
    return
  end
  return parse_enum(enum_node, buffer)
end

-- Return whether a line contains only whitespace and comments. block_comment
-- carries state between lines so license headers can be skipped without
-- mistaking code after a closing */ on the same line for preamble trivia.
local function is_cpp_trivia_line(line, block_comment)
  local rest = line

  while true do
    rest = rest:match('^%s*(.*)$')
    if block_comment then
      local close = rest:find('*/', 1, true)
      if close == nil then
        return true, true
      end
      rest = rest:sub(close + 2)
      block_comment = false
    elseif rest == '' or rest:sub(1, 2) == '//' then
      return true, false
    elseif rest:sub(1, 2) == '/*' then
      block_comment = true
      rest = rest:sub(3)
    else
      return false, false
    end
  end
end

-- Parse the file preamble once and share the result between include insertion
-- and guard correction. A conventional guard may follow license comments and
-- may contain whitespace or comments between #ifndef and #define.
local function parse_cpp_preamble(lines)
  local row = 1
  local block_comment = false
  while lines[row] ~= nil do
    local is_trivia
    is_trivia, block_comment = is_cpp_trivia_line(lines[row], block_comment)
    if not is_trivia then
      break
    end
    row = row + 1
  end

  local preamble = {
    depth = 0,
    after_comments = row - 1,
  }

  local guard_name = lines[row] and lines[row]:match('^%s*#%s*ifndef%s+([%w_]+)%s*$')
  if guard_name == nil then
    return preamble
  end

  local define_row = row + 1
  block_comment = false
  while lines[define_row] ~= nil do
    local is_trivia
    is_trivia, block_comment = is_cpp_trivia_line(lines[define_row], block_comment)
    if not is_trivia then
      break
    end
    define_row = define_row + 1
  end

  local defined_name, define_suffix = lines[define_row] and lines[define_row]:match('^%s*#%s*define%s+([%w_]+)%s*(.*)$')
  if define_suffix ~= nil and define_suffix ~= '' and not define_suffix:match('^//') then
    defined_name = nil
  end
  if defined_name ~= guard_name then
    return preamble
  end

  local depth = 0
  local endif_row
  for candidate = row, #lines do
    local directive = lines[candidate]:match('^%s*#%s*(%a+)')
    if directive == 'if' or directive == 'ifdef' or directive == 'ifndef' then
      depth = depth + 1
    elseif directive == 'endif' then
      depth = depth - 1
      if depth == 0 then
        endif_row = candidate
        break
      end
    end
  end

  -- Do not treat an unterminated conditional as a valid include guard.
  if endif_row == nil then
    return preamble
  end

  return {
    depth = 1,
    after_comments = row - 1,
    after_define = define_row,
    ifndef_row = row,
    define_row = define_row,
    endif_row = endif_row,
    name = guard_name,
  }
end

-- Read the current includes
-- Divide them and sort them internally in the following groups:
--
-- #include "same_dir.h"
-- #include "other/directory.h"
--
-- #include <external/includes.h>
--
-- #include <system_includes>
function M.divide_and_sort_includes()
  local includes = { external = {}, system = {}, internal = {}, internal_same_dir = {}, internal_my_own = {} }
  local locations = { start_row = nil, end_row = nil }

  local function compare_location(node)
    local row, _, _, _ = vim.treesitter.get_node_range(node)
    if locations.start_row == nil then
      locations.start_row = row
    else
      locations.start_row = math.min(row, locations.start_row)
    end

    if locations.end_row == nil then
      locations.end_row = row
    else
      locations.end_row = math.max(row, locations.end_row)
    end
  end

  -- POSIX headers
  local c_headers = require('srydell.data.c_headers')
  -- C++ standard library headers
  local cpp_headers = require('srydell.data.cpp_headers')
  local function is_system(text)
    return cpp_headers[text] ~= nil or c_headers[text] ~= nil
  end

  -- if this file is 'hello.cpp' root_of_file = 'hello'
  local root_of_file = '"' .. vim.fn.expand('%:t:r')
  local possible_headers_to_this = { root_of_file .. '.h"', root_of_file .. '.hpp"', root_of_file .. '.hxx"' }
  local function is_header_to_this(include)
    for _, possible_header in ipairs(possible_headers_to_this) do
      if include == possible_header then
        return true
      end
    end
    return false
  end

  local function append_include(text, node, suffix)
    local include = { text = text, node = node, suffix = suffix }
    if node:type() == 'string_literal' then
      -- E.g. "myLib/stuff.h"
      -- or "local_stuff.h"
      if text:find('/') == nil then
        if is_header_to_this(text) then
          table.insert(includes['internal_my_own'], include)
        else
          table.insert(includes['internal_same_dir'], include)
        end
      else
        table.insert(includes['internal'], include)
      end
    else
      -- E.g. <vector>
      -- or <boost/program_options.hpp>
      if is_system(text) then
        table.insert(includes['system'], include)
      else
        table.insert(includes['external'], include)
      end
    end
  end

  local has_alignment_header = false
  local function collect_include(node)
    if node:type() == 'preproc_include' then
      for child, name in node:iter_children() do
        if name ~= nil and name == 'path' then
          local text = M.get_node_text(child, 0)
          -- Alignment headers are often used as paired sentinels. Leave the
          -- include block untouched rather than moving or deleting them.
          if text:find('align_int8.h') ~= nil or text:find('align_restore.h') ~= nil then
            has_alignment_header = true
            return true
          end

          compare_location(child)
          local row, _, _, end_column = vim.treesitter.get_node_range(child)
          local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
          -- Preserve everything following the path, most importantly comments
          -- explaining why an include exists. The directive's leading spacing
          -- is still normalized by the sorter.
          local suffix = line:sub(end_column + 1)
          append_include(text, child, suffix)
        end
      end
    end
    -- Do not stop the search
    return false
  end

  M.search_down_from_root_until(collect_include)

  if has_alignment_header then
    return
  end

  -- No includes
  if locations.start_row == nil or locations.end_row == nil then
    return
  end

  -- If code is found between the includes
  -- -> give up
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, locations.start_row, locations.end_row, false)) do
    if line:match('^%s*$') == nil and line:find('^%s*#%s*include%s+') == nil then
      return
    end
  end

  -- Sort the include within their category
  for _, includes_and_nodes in pairs(includes) do
    table.sort(includes_and_nodes, function(inc_a, inc_b)
      return inc_a.text < inc_b.text
    end)
  end

  -- Create the new include lines
  local lines = {}
  for _, category in ipairs({ 'internal_my_own', 'internal_same_dir', 'internal', 'external', 'system' }) do
    -- Only add empty lines between { internal* } { external } { system }
    if category == 'external' or category == 'system' and #includes[category] > 0 then
      if #includes[category] > 0 then
        table.insert(lines, '')
      end
    end
    for _, include in ipairs(includes[category]) do
      table.insert(lines, '#include ' .. include.text .. include.suffix)
    end
  end

  -- Pop the first newline
  if not vim.tbl_isempty(lines) and lines[1] == '' then
    table.remove(lines, 1)
  end

  -- Replace the current include block with the new one
  vim.api.nvim_buf_set_lines(0, locations.start_row, locations.end_row + 1, true, lines)
end

-- Read the include guard if there is one.
-- Correct it so that it follows the standard below:
-- PROJECT_PATH_TO_FILE_EXTENSION
-- e.g
-- MYPROJECT_INCLUDE_API_H
M.correct_include_guard = function()
  -- Use source lines instead of Tree-sitter nodes because this runs during
  -- BufWritePre, when a parser may not be attached or its tree may be stale.
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local preamble = parse_cpp_preamble(lines)
  if preamble.name == nil then
    return
  end

  local util = require('srydell.util')
  local include_guard = util.get_include_guard(util.get_project())
  if include_guard == '' then
    return
  end

  -- The pair and matching #endif were validated together. Preserve directive
  -- spacing and update a conventional closing comment when it names the old
  -- guard; unrelated comments remain untouched.
  lines[preamble.ifndef_row] = lines[preamble.ifndef_row]:gsub('(#%s*ifndef%s+)[%w_]+', '%1' .. include_guard, 1)
  lines[preamble.define_row] = lines[preamble.define_row]:gsub('(#%s*define%s+)[%w_]+', '%1' .. include_guard, 1)

  local old_name = vim.pesc(preamble.name)
  lines[preamble.endif_row] =
    lines[preamble.endif_row]:gsub('(//%s*)' .. old_name .. '(%s*)$', '%1' .. include_guard .. '%2', 1)
  lines[preamble.endif_row] =
    lines[preamble.endif_row]:gsub('(/%*%s*)' .. old_name .. '(%s*%*/%s*)$', '%1' .. include_guard .. '%2', 1)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- Add an include to the list of includes in the current file
-- E.g. add_includes({ '<atomic>' })
-- Checks if it was there before and uses divide_and_sort_includes
-- to tidy the includes after
M.add_includes = function(includes)
  if includes == nil or vim.tbl_isempty(includes) then
    return
  end

  -- Return the preprocessor nesting depth at each source line. Includes added
  -- by this function must be placed at the file's effective top level: depth
  -- zero in source files, or depth one inside a conventional include guard.
  -- In particular, an existing include nested in an unrelated #if must never
  -- become the insertion point for a newly inferred dependency.
  local function get_line_depths(lines)
    local depths = {}
    local depth = 0

    for row, line in ipairs(lines) do
      local directive = line:match('^%s*#%s*(%a+)')
      if directive == 'endif' then
        depth = math.max(0, depth - 1)
      end

      depths[row] = depth

      if directive == 'if' or directive == 'ifdef' or directive == 'ifndef' then
        depth = depth + 1
      end
    end

    return depths
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local depths = get_line_depths(lines)
  local guard = parse_cpp_preamble(lines)

  -- Only an include at the effective top level satisfies an unconditional
  -- dependency. For example, <vector> inside #if FEATURE must not suppress an
  -- unconditional <vector> needed by code outside that conditional.
  local existing_includes = {}
  local first_row = nil
  local function collect_include(node)
    if node:type() == 'preproc_include' then
      for child, name in node:iter_children() do
        if name ~= nil and name == 'path' then
          local row = M.get_row(node)
          if depths[row + 1] == guard.depth then
            existing_includes[M.get_node_text(child, 0)] = true
            if first_row == nil then
              first_row = row
            else
              first_row = math.min(first_row, row)
            end
          end
        end
      end
    end
    -- Do not stop the search
    return false
  end

  M.search_down_from_root_until(collect_include)

  local includes_to_add = {}
  for _, include in ipairs(includes) do
    if existing_includes[include] ~= true then
      table.insert(includes_to_add, '#include ' .. include)
    end
  end

  if vim.tbl_isempty(includes_to_add) then
    return
  end

  if first_row == nil then
    local pragma_once_row
    if guard.after_define == nil then
      for row, line in ipairs(lines) do
        if line:match('^%s*#%s*pragma%s+once%s*$') then
          pragma_once_row = row
          break
        end
      end
    end

    -- Insert after the actual file preamble, never merely after the first blank
    -- line: that blank may follow a using-declaration or other code which
    -- already needs the inferred header. Consume only blank lines immediately
    -- following the guard, #pragma once, or leading license comments.
    local preamble_end = guard.after_define or pragma_once_row or guard.after_comments or 0
    while
      lines[preamble_end + 1] ~= nil
      and lines[preamble_end + 1]:match('^%s*$')
      and depths[preamble_end + 1] == guard.depth
    do
      preamble_end = preamble_end + 1
    end
    first_row = preamble_end
    table.insert(includes_to_add, '')
  end

  vim.api.nvim_buf_set_lines(0, first_row, first_row, true, includes_to_add)
end

-- Remove template part
-- i.e. std::vector<int> -> std::vector
M.remove_template = function(type_string)
  local template = type_string:find('<', 1, true)
  if template then
    type_string = type_string:sub(1, template - 1)
  end
  return type_string
end

-- Look through the types in the current file.
-- Include the necessary standard library headers for those types.
-- Avoid doubles.
-- Argument user_includes provides a way to add user defined includes. E.g.
-- include_necessary_types({
--   ['fmt::format'] = '<fmt/format.h>',
-- })
M.include_necessary_types = function(user_includes)
  -- require() caches tables. Copy the built-in mapping before applying
  -- buffer/project-specific overrides so they cannot leak into later calls.
  local known_includes = vim.tbl_extend('force', {}, require('srydell.data.types_to_headers'), user_includes or {})
  local transitive_includes = require('srydell.data.transitive_includes')

  local unique_includes = {}
  local to_be_skipped = {}
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'cpp')
  if not ok or parser == nil then
    return
  end

  -- The query lives in queries/cpp/includes.scm so the syntax patterns remain
  -- visible, testable configuration rather than an opaque Lua string.
  local query = vim.treesitter.query.get('cpp', 'includes')
  if query == nil then
    return
  end

  local function add_include_for(type)
    local include = known_includes[type]
    if include == nil then
      return
    end

    unique_includes[include] = true
    for _, transitive in ipairs(transitive_includes[include] or {}) do
      to_be_skipped[transitive] = true
    end
  end

  local function starts_before(node, other)
    local row, column = node:start()
    local other_row, other_column = other:start()
    return row < other_row or row == other_row and column < other_column
  end

  local function contains(ancestor, node)
    while node ~= nil do
      if node == ancestor then
        return true
      end
      node = node:parent()
    end
    return false
  end

  local function distance_to_ancestor(node, ancestor)
    local distance = 0
    while node ~= nil do
      if node == ancestor then
        return distance
      end
      node = node:parent()
      distance = distance + 1
    end
  end

  -- A type_identifier that names the template portion of std::vector<int> is
  -- already covered by the surrounding qualified_identifier. Template
  -- arguments such as `string` remain eligible for unqualified resolution.
  local function is_name_of_qualified_identifier(node)
    local parent = node:parent()
    if parent == nil or parent:type() ~= 'template_type' then
      return false
    end

    local grandparent = parent:parent()
    if grandparent == nil or grandparent:type() ~= 'qualified_identifier' then
      return false
    end

    for _, name_node in ipairs(grandparent:field('name')) do
      if name_node == parent then
        return true
      end
    end
    return false
  end

  local function import_scope(node)
    -- A using-declaration affects the remainder of its immediate translation
    -- unit, namespace body, or compound statement.
    return node:parent()
  end

  for _, tree in ipairs(parser:parse() or {}) do
    local imports = {}
    local aliases = {}
    local candidates = {}

    for capture_id, node in query:iter_captures(tree:root(), 0) do
      local capture = query.captures[capture_id]
      if capture == 'symbol.qualified' then
        table.insert(candidates, { kind = 'qualified', node = node })
      elseif capture == 'using.namespace' then
        table.insert(imports, {
          kind = 'namespace',
          name = M.get_node_text(node),
          node = node,
          scope = import_scope(node:parent()),
        })
      elseif capture == 'using.symbol' then
        table.insert(imports, {
          kind = 'symbol',
          name = M.get_node_text(node),
          node = node,
          scope = import_scope(node:parent()),
        })
      elseif capture == 'namespace.alias' then
        local name_nodes = node:field('name')
        local target = node:named_child(1)
        -- Be deliberately strict about malformed/incomplete syntax. An alias
        -- without exactly one name and a namespace-like target is unusable and
        -- must not influence include inference while the user is still typing.
        if
          #name_nodes == 1
          and target ~= nil
          and (target:type() == 'namespace_identifier' or target:type() == 'nested_namespace_specifier')
        then
          table.insert(aliases, {
            name = M.get_node_text(name_nodes[1]),
            target = M.get_node_text(target),
            node = node,
            scope = node:parent(),
          })
        end
      elseif capture == 'symbol.unqualified_type' then
        if not is_name_of_qualified_identifier(node) then
          table.insert(candidates, { kind = 'unqualified', node = node })
        end
      elseif capture == 'symbol.unqualified_function' then
        table.insert(candidates, { kind = 'unqualified', node = node })
      end
    end

    -- Resolve the first component of a namespace through the closest visible
    -- alias. Inner scopes shadow outer scopes; declaration order is respected.
    -- Alias chains are supported, while cycles and excessively deep malformed
    -- chains are rejected rather than risking a save-time loop.
    local function resolve_aliases(namespace, reference)
      namespace = namespace:gsub('^::', '')
      local seen = {}
      for _ = 1, 32 do
        local first, suffix = namespace:match('^([^:]+)(.*)$')
        if first == nil then
          return namespace
        end

        local best
        local best_distance
        local ambiguous = false
        for _, alias in ipairs(aliases) do
          local distance = distance_to_ancestor(reference, alias.scope)
          if alias.name == first and distance ~= nil and starts_before(alias.node, reference) then
            if best == nil or distance < best_distance then
              best = alias
              best_distance = distance
              ambiguous = false
            elseif distance == best_distance then
              -- Redeclaring an alias in one scope is invalid C++. While such a
              -- buffer is incomplete, reject the lookup instead of guessing
              -- which declaration the user intends to keep.
              ambiguous = true
            end
          end
        end

        if ambiguous then
          return nil
        elseif best == nil then
          return namespace
        end
        if seen[best] then
          return nil
        end
        seen[best] = true
        namespace = best.target .. suffix
      end
      return nil
    end

    for _, candidate_info in ipairs(candidates) do
      local candidate = candidate_info.node
      if candidate_info.kind == 'qualified' then
        local qualified_name = resolve_aliases(M.remove_template(M.get_node_text(candidate)), candidate)
        if qualified_name ~= nil then
          add_include_for(qualified_name)
        end
      else
        local short_name = M.get_node_text(candidate)
        local matches = {}

        for _, import in ipairs(imports) do
          if starts_before(import.node, candidate) and contains(import.scope, candidate) then
            local qualified_name
            if import.kind == 'symbol' and import.name:match('::([^:]+)$') == short_name then
              qualified_name = resolve_aliases(import.name, import.node)
            elseif import.kind == 'namespace' then
              local namespace = resolve_aliases(import.name, import.node)
              if namespace ~= nil then
                qualified_name = namespace .. '::' .. short_name
              end
            end

            if qualified_name ~= nil and known_includes[qualified_name] ~= nil then
              matches[qualified_name] = true
            end
          end
        end

        -- Multiple imported namespaces may expose the same spelling. Without
        -- semantic information from clangd, declining an ambiguous match is the
        -- only safe choice.
        local resolved
        for qualified_name in pairs(matches) do
          if resolved ~= nil then
            resolved = nil
            break
          end
          resolved = qualified_name
        end
        if resolved ~= nil then
          add_include_for(resolved)
        end
      end
    end
  end

  local includes = {}

  for include, _ in pairs(unique_includes) do
    if to_be_skipped[include] == nil then
      table.insert(includes, include)
    end
  end

  -- pairs() has no defined iteration order. Stable input keeps direct callers
  -- deterministic even before divide_and_sort_includes() runs on save.
  table.sort(includes)
  M.add_includes(includes)
end

M.get_class_name = function(class_node, buffer)
  buffer = buffer or 0
  for child, name in class_node:iter_children() do
    if name == 'name' then
      return M.get_node_text(child, buffer)
    end
  end
end

-- Look for a class under the cursor.
-- Return the name as a string
M.get_class_name_under_cursor = function()
  local class_node = M.search_up_until(get_node_at_cursor(), M.is_class_or_struct)
  if class_node == nil then
    return
  end

  return M.get_class_name(class_node)
end

-- Look at the line where the cursor is.
-- Return the indentation of that line as a string.
local function get_indentation()
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

-- If there is a class where the cursor is:
-- Create deleted move constructors
M.make_class_no_move = function()
  local name = M.get_class_name_under_cursor()
  if name == nil then
    return
  end

  local indentation = get_indentation()

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local no_move = {
    string.format('%s No move', indentation),
    string.format('%s%s(%s const &&) = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s const &&) = delete;', indentation, name, name),
  }

  vim.api.nvim_buf_set_lines(0, row, row, true, no_move)
end

-- If there is a class where the cursor is:
-- Create deleted copy constructors
M.make_class_no_copy = function()
  local name = M.get_class_name_under_cursor()
  if name == nil then
    return
  end

  local indentation = get_indentation()

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local no_copy = {
    string.format('%s No copy', indentation),
    string.format('%s%s(%s &) = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s &) = delete;', indentation, name, name),
  }

  vim.api.nvim_buf_set_lines(0, row, row, true, no_copy)
end

local function load_alternative_file()
  local cpp_util = require('srydell.util.cpp')
  local alt_file = cpp_util.get_alternative_file()
  if alt_file == nil then
    return
  end

  local buffer = vim.fn.bufadd(alt_file)
  vim.fn.bufload(buffer)

  return buffer
end

-- Definer means either constructor or destructor
local function make_definer_within_class_boundary(class_name, indentation, is_source)
  local ls = require('luasnip')
  local fmta = require('luasnip.extras.fmt').fmta

  local ctor = {}
  if is_source then
    -- Implementation
    local ctor_str = [[
    %s(<>) {
      <>
    }
  ]]
    ctor = fmta(ctor_str:format(class_name), {
      ls.i(1),
      ls.i(0),
    })
  else
    -- Declaration
    local ctor_str = [[
    %s(<>);
  ]]
    ctor = fmta(ctor_str:format(class_name), {
      ls.i(1),
    })
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  -- Create a blank line to start from
  vim.api.nvim_buf_set_lines(0, pos[1], pos[1], false, { indentation })
  -- Start at the indentation of the class
  pos[2] = #indentation
  ls.snip_expand(ls.snippet({}, ctor), { pos = pos })
end

local function build_parameter_snippet(function_node, buffer)
  local parameters = M.search_down_until(function_node, M.is_parameters)

  if parameters == nil then
    return
  end

  local function remove_default_value(param)
    if param:type() ~= 'optional_parameter_declaration' then
      return M.get_node_text(param, buffer)
    end

    local text = M.get_node_text(param, buffer)
    -- Remove the default value part
    -- Note, there has to be one as this is an optional_parameter_declaration
    text = text:sub(1, text:find('=') - 1)
    -- Remove trailing whitespace
    text = text:gsub('%s+$', '')
    return text
  end

  local ls = require('luasnip')

  local insert_nodes = {}
  local all_params = '('
  local function concatenate_params(node)
    -- Simple parameter or with a default value
    if M.is_parameter(node) then
      local name = M.search_down_until(node, is_identifier)
      local parameter = remove_default_value(node)
      -- Escape for luasnip.fmta
      parameter = parameter:gsub('<', '<<')
      parameter = parameter:gsub('>', '>>')

      if name ~= nil then
        all_params = all_params .. parameter .. ', '
      else
        -- No name parameter
        -- Add a insert node
        all_params = all_params .. parameter .. ' <>, '
        local count = #insert_nodes + 1
        table.insert(insert_nodes, ls.insert_node(count))
      end
    end
  end
  M.search_down_until(parameters, concatenate_params)

  -- Remove the last ', '
  -- and close the parenthesis
  if all_params:sub(#all_params - 1, #all_params) == ', ' then
    all_params = all_params:sub(1, -3)
  end
  all_params = all_params .. ')'

  return { params = all_params, snip_nodes = insert_nodes }
end

-- info = { node: TSNode, buffer: Int }
-- Where info.node is a function
M.build_function_snippet = function(info)
  local ls = require('luasnip')
  local fmta = require('luasnip.extras.fmt').fmta
  local sn = ls.snippet_node

  local function_name_node = M.search_down_until(info.node, M.is_function_name)
  if function_name_node == nil then
    return
  end
  local function_name = M.get_node_text(function_name_node, info.buffer)

  -- If there it is a class function, prepend 'ClassName::'
  local surrounding_class_node = M.search_up_until(info.node, M.is_class_or_struct)
  if surrounding_class_node ~= nil then
    function_name = M.get_class_name(surrounding_class_node, info.buffer) .. '::' .. function_name
  end

  local param_snippet = build_parameter_snippet(info.node, info.buffer)
  if param_snippet == nil then
    return
  end

  local return_type = get_function_return_for_snippet(info.node, info.buffer)
  local qualifiers = get_function_qualifiers_for_snippet(info.node, info.buffer)

  local insert_count = #param_snippet.snip_nodes
  -- For getting into the {}
  table.insert(param_snippet.snip_nodes, ls.insert_node(insert_count + 1))
  -- To be able to switch between the options
  table.insert(param_snippet.snip_nodes, ls.insert_node(insert_count + 2))

  local snip_body = string.format(
    [[%s%s%s%s {
  <><>
}]],
    return_type,
    function_name,
    param_snippet.params,
    qualifiers
  )

  return sn(nil, fmta(snip_body, param_snippet.snip_nodes))
end

-- Definer means either constructor or destructor
local function make_definer_outside_of_class_boundary(definers)
  local snip_choices = {}
  for _, f in ipairs(definers) do
    local _, info = unpack(f)
    -- Remove the parameter list
    -- MyClass::MyClass(int i) -> MyClass::MyClass
    local snippet = M.build_function_snippet(info)

    if snippet ~= nil then
      table.insert(snip_choices, snippet)
    end
  end

  if vim.tbl_isempty(snip_choices) then
    return
  end

  local ls = require('luasnip')
  local snippet = ls.snippet({}, {
    ls.choice_node(1, snip_choices),
  })

  local pos = vim.api.nvim_win_get_cursor(0)
  -- Create a blank line to start from
  vim.api.nvim_buf_set_lines(0, pos[1], pos[1], false, { '' })
  pos[2] = 0
  ls.snip_expand(snippet, { pos = pos })
end

M.find_not_implemented_functions = function()
  local declared_functions = {}
  local implemented_functions = {}

  local buffers = { 0, load_alternative_file() }
  for _, buffer in ipairs(buffers) do
    local function collect_functions(node)
      if M.is_function(node) then
        local name = get_compressed_function_name(node, buffer)
        if M.is_function_implementation(node) then
          implemented_functions[name] = {
            node = node,
            buffer = buffer,
          }
        else
          declared_functions[name] = {
            node = node,
            buffer = buffer,
          }
        end
      end
    end

    M.search_down_from_root_until(collect_functions, buffer)
  end

  for f, _ in pairs(implemented_functions) do
    -- Remove the found implementations
    declared_functions[f] = nil
  end

  -- To sort and flatten the result
  local missing_implementations = {}
  for f, info in pairs(declared_functions) do
    table.insert(missing_implementations, { f, info })
  end
  -- Sort them by name to make it more predictable
  table.sort(missing_implementations, function(f_a, f_b)
    return f_a[1] < f_b[1]
  end)

  -- vim.print('Implemented:')
  -- vim.print(implemented_functions)
  -- vim.print('Missing:')
  -- vim.print(missing_implementations)

  -- Return the not implemented functions
  return missing_implementations
end

local function keep_only_destructors(functions)
  local filtered = {}
  for _, f in ipairs(functions) do
    local function_name, _ = unpack(f)
    -- Remove the parameter list
    -- void f(int i) -> void f
    local name = function_name:sub(1, function_name:find('%(') - 1)

    -- Check if there is a space (return type)
    -- or if it contains a '~' (destructor)
    if name:find(' ') == nil and name:find('~') ~= nil then
      table.insert(filtered, f)
    end
  end
  return filtered
end

local function keep_only_constructors(functions)
  local filtered = {}
  for _, f in ipairs(functions) do
    local function_name, _ = unpack(f)
    -- Remove the parameter list
    -- void f(int i) -> void f
    local name = function_name:sub(1, function_name:find('%(') - 1)

    -- Check if there is a space (return type)
    -- or if it contains a '~' (destructor)
    if name:find(' ') == nil and name:find('~') == nil then
      table.insert(filtered, f)
    end
  end
  return filtered
end

-- Could be either constructor or destructor
-- Filter on is a function that removes functions that are not either
-- constructor or destructor
local function make_class_definer(is_constructor)
  local indentation = get_indentation()
  if #indentation == 0 then
    -- Default guess
    indentation = string.rep(' ', vim.opt.shiftwidth:get())
  end

  local extension = vim.fn.expand('%:e')
  local is_source = extension == 'cpp' or extension == 'cxx'
  local class_name = M.get_class_name_under_cursor()
  if class_name == nil then
    if not is_source then
      -- Do nothing if not within a class and in a header
      return
    end

    -- Declared but not defined
    local filter_on = nil
    if is_constructor then
      filter_on = keep_only_constructors
    else
      filter_on = keep_only_destructors
    end
    local without_implementation = filter_on(M.find_not_implemented_functions())
    make_definer_outside_of_class_boundary(without_implementation)
  else
    if not is_constructor then
      class_name = '~' .. class_name
    end
    make_definer_within_class_boundary(class_name, indentation, is_source)
  end
end

-- When called within a class boundary:
--   When header file:
--     Create a declaration.
--   When source file:
--     Create a implementation.
--
-- When called outside a class boundary:
--   When header file:
--     Do nothing.
--   When source file:
--     Look in the corresponding header file
--     for classes.
--     Give the not implemented constructors
--     as options.
M.make_class_constructor = function()
  local is_constructor = true
  make_class_definer(is_constructor)
end

M.make_class_destructor = function()
  local is_constructor = false
  make_class_definer(is_constructor)
end

return M
