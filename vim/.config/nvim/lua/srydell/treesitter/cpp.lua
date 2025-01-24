local M = {}

local function get_node_text(node, buffer)
  buffer = buffer or 0
  return vim.treesitter.get_node_text(node, buffer)
end

local function get_row(node)
  local row, _, _, _ = vim.treesitter.get_node_range(node)
  return row
end

-- Go up the treesitter tree until stop condition is met.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
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

-- Go down the treesitter tree from node until stop condition is met.
-- Visit the nodes in breadth first.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
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
      table.insert(nodes, child)
    end
  end
end

-- Parse the buffer content and search down from the root
-- until a stop condition is met or there are no more nodes.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
local function search_down_from_root_until(stop_condition, buffer)
  buffer = buffer or 0
  local trees = vim.treesitter.get_parser(buffer, 'cpp'):parse()
  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root == nil then
      return
    end

    local end_node = search_down_until(tree:root(), stop_condition)
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

-- A version of the ts_utils one that reparses the tree
-- Useful when you're trying to act on something that you have not saved yet.
-- Use when not caring about performance
local function get_node_at_cursor(winnr)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)
  local trees = vim.treesitter.get_parser(buf, 'cpp'):parse()
  for _, tree in ipairs(trees) do
    local root = tree:root()

    return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
  end
end

-- A set of is_* functions to be used when searching for nodes.

local function is_identifier(node)
  return node:type() == 'identifier'
end

local function is_parameters(node)
  return node:type() == 'parameter_list'
end

local function is_parameter(node)
  return node:type() == 'parameter_declaration' or node:type() == 'optional_parameter_declaration'
end

local is_function = function(node)
  return node:type() == 'function_declarator'
end

local is_class_or_struct = function(node)
  return node:type() == 'class_specifier' or node:type() == 'struct_specifier'
end

local is_function_name = function(node)
  return node:type() == 'identifier' -- Simple free function
    or node:type() == 'field_identifier' -- Class function
    or node:type() == 'qualified_identifier' -- Function with namespace qualifier
    or node:type() == 'destructor_name' -- Destructor
    or node:type() == 'operator_name' -- Operator
end

-- Assumes the input function_node is function_node:type() == 'function_declarator'
local is_function_implementation = function(function_node)
  local function is_implementation(node)
    -- Implemented function
    return node:type() == 'function_definition'
  end

  local implementation = search_up_until(function_node, is_implementation)
  return implementation ~= nil
end

-- Goes through a node of type qualified_identifier
-- If it is a template, go through each template argument and see if
-- it is considered 'primitive'. Primitive args are 'int', 'double', etc.
-- If all of them are, return true. Else, return false
local function are_all_template_args_primitive(qualified_identifier)
  local template_type = qualified_identifier:field('name')[1]
  if template_type == nil then
    return false
  end

  local arguments = template_type:field('arguments')[1]
  if arguments == nil then
    return false
  end

  for arg, _ in arguments:iter_children() do
    if arg:type() == 'type_descriptor' then
      -- Check the internal type
      local type = arg:field('type')[1]
      if type == nil then
        return false
      end
      if type:type() ~= 'primitive_type' then
        return false
      end
    end
  end

  return true
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
  return search_up_until(node_at_cursor, is_argument)
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
  return search_up_until(node_at_cursor, in_function)
end

-- Removes the name and the default parameter values from the parameters.
-- Also removes whitespace to make it easier to compare parameters as strings.
-- I.e. (std::string my_string, int i = 5) -> (std::string,int)
local function clean_params(params_node, buffer)
  buffer = buffer or 0
  local params = '('
  local function concatenate_params(node)
    -- Simple parameter or with a default value
    if is_parameter(node) then
      -- The whole parameter - e.g. 'std::string const & s = "hi"'
      local name = search_down_until(node, is_identifier)
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
          params = params .. get_node_text(node, buffer) .. ','
        else
          -- Optional parameter with no name? Yikes.
          -- Remove anything after the '='
          local param_name = get_node_text(node, buffer)
          param_name = param_name:sub(1, param_name:find('=') - 1)
          params = params .. param_name .. ','
        end
      end
    end
  end

  search_down_until(params_node, concatenate_params)
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
  local parameters_node = search_down_until(function_node, is_parameters)
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
  local function_name_node = search_down_until(function_node, is_function_name)

  -- Give up
  if function_name_node == nil then
    return ''
  end

  local function is_function_root(node)
    return node:type() == 'declaration' or node:type() == 'field_declaration' or node:type() == 'function_definition'
  end

  local function_root = search_up_until(function_node, is_function_root)
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

  local class_node = search_up_until(function_node, is_class_or_struct)
  local class_prefix = ''
  if class_node ~= nil then
    class_prefix = M.get_class_name(class_node, buffer) .. '::'
  end

  for child, _ in function_node:iter_children() do
    -- Name of the function
    if is_function_name(child) then
      compressed_name = compressed_name .. class_prefix .. get_node_text(child, buffer)
    end

    if is_parameters(child) then
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
  wrap_node_in('', variable, '.load(std::memory_order_acquire)')
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

  local enum_node = search_down_from_root_until(is_our_enum, buffer)
  if enum_node == nil then
    return
  end
  return parse_enum(enum_node, buffer)
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

  local function append_include(text, node)
    if node:type() == 'string_literal' then
      -- E.g. "myLib/stuff.h"
      -- or "local_stuff.h"
      if text:find('/') == nil then
        if is_header_to_this(text) then
          table.insert(includes['internal_my_own'], { text, node })
        else
          table.insert(includes['internal_same_dir'], { text, node })
        end
      else
        table.insert(includes['internal'], { text, node })
      end
    else
      -- E.g. <vector>
      -- or <boost/program_options.hpp>
      if is_system(text) then
        table.insert(includes['system'], { text, node })
      else
        table.insert(includes['external'], { text, node })
      end
    end
  end

  local function collect_include(node)
    if node:type() == 'preproc_include' then
      for child, name in node:iter_children() do
        if name ~= nil and name == 'path' then
          local text = get_node_text(child, 0)
          -- Avoid alignment headers
          if text:find('align_int8.h') == nil and text:find('align_restore.h') == nil then
            compare_location(child)
            append_include(text, child)
          end
        end
      end
    end
    -- Do not stop the search
    return false
  end

  search_down_from_root_until(collect_include)

  -- No includes
  if locations.start_row == nil or locations.end_row == nil then
    return
  end

  -- If code is found between the includes
  -- -> give up
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, locations.start_row, locations.end_row, false)) do
    if line ~= '' and line:find('^#include') == nil then
      return
    end
  end

  -- Sort the include within their category
  for _, includes_and_nodes in pairs(includes) do
    table.sort(includes_and_nodes, function(inc_a, inc_b)
      return inc_a[1] < inc_b[1]
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
    for _, text_and_node in ipairs(includes[category]) do
      table.insert(lines, '#include ' .. text_and_node[1])
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
  local guard = { ifdef = nil, define = nil }

  local function get_guard(node)
    -- #ifndef MY_GUARD
    if node:type() == 'preproc_ifdef' or node:type() == 'preproc_if' then
      local identifier = search_down_until(node, is_identifier)
      guard.ifdef = identifier
    elseif node:type() == 'preproc_def' then
      local identifier = search_down_until(node, is_identifier)
      guard.define = identifier
    end

    -- Stop when both found
    return false
    -- return guard.ifdef ~= nil and guard.define ~= nil
  end

  search_down_from_root_until(get_guard)

  -- No include guard
  if guard.ifdef == nil or guard.define == nil then
    return
  end

  -- Existing include guards are not separated by lines
  if get_row(guard.define) ~= get_row(guard.ifdef) + 1 then
    return
  end

  local util = require('srydell.util')
  local include_guard = util.get_include_guard(util.get_project())
  if include_guard == '' then
    return
  end

  -- Put in the new include guard
  -- Have to divide it up as otherwise
  -- there is a change in the node range before the second node is checked
  local to_change = {}
  for _, node in pairs(guard) do
    table.insert(to_change, { vim.treesitter.get_node_range(node) })
  end

  for _, value in ipairs(to_change) do
    local start_row, start_col, end_row, end_col = unpack(value)
    vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { include_guard })
  end
end

-- Add an include to the list of includes in the current file
-- E.g. add_includes({ '<atomic>' })
-- Checks if it was there before and uses divide_and_sort_includes
-- to tidy the includes after
M.add_includes = function(includes)
  if includes == nil or vim.tbl_isempty(includes) then
    return
  end

  -- Get all the existing includes
  local existing_includes = {}
  local first_row = nil
  local function collect_include(node)
    if node:type() == 'preproc_include' then
      for child, name in node:iter_children() do
        if name ~= nil and name == 'path' then
          existing_includes[get_node_text(child, 0)] = true
          if first_row == nil then
            first_row = get_row(node)
          else
            first_row = math.min(first_row, get_row(node))
          end
        end
      end
    end
    -- Do not stop the search
    return false
  end

  search_down_from_root_until(collect_include)

  local includes_to_add = {}
  for _, include in ipairs(includes) do
    if existing_includes[include] ~= true then
      -- Already there
      table.insert(includes_to_add, '#include ' .. include)
    end
  end

  local function get_first_empty_row()
    for number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 50, false)) do
      if line == '' then
        return number
      end
    end
    return 0
  end

  if first_row == nil then
    -- No includes, find the first empty line to add them
    local first_empty_row = get_first_empty_row()
    if first_empty_row == nil then
      return
    end
    first_row = first_empty_row
    -- If there were no includes before,
    -- also add an extra empty row after it
    table.insert(includes_to_add, '')
  end

  vim.api.nvim_buf_set_lines(0, first_row, first_row, true, includes_to_add)
end

-- Remove template part
-- i.e. std::vector<int> -> std::vector
local function remove_template(type_string)
  local template = type_string:find('<', 1, true)
  if template then
    type_string = type_string:sub(1, template - 1)
  end
  return type_string
end

local function has_code_within_includes()
  local has_seen_include = false
  local has_seen_code_after_first_include = false

  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local is_include = line:find('^#include') ~= nil
    local is_empty_line = line == ''
    local is_code = not is_include and not is_empty_line

    -- Is this the first include in the file?
    if is_include and not has_seen_include then
      has_seen_include = true
    -- Code after the first include?
    elseif is_code and has_seen_include then
      has_seen_code_after_first_include = true
    end

    -- Code between the first include and one that is seen now?
    if has_seen_include and has_seen_code_after_first_include and is_include then
      return true
    end
  end

  return false
end

-- Look through the types in the current file.
-- Include the necessary standard library headers for those types.
-- Avoid doubles.
-- Argument user_includes provides a way to add user defined includes. E.g.
-- include_necessary_types({
--   ['fmt::format'] = '<fmt/format.h>',
-- })
M.include_necessary_types = function(user_includes)
  if has_code_within_includes() then
    -- Give up early
    return
  end

  -- Are there code within the current includes? Give up
  local known_includes = require('srydell.data.types_to_headers')

  -- Merge the user provided with the standard library ones
  user_includes = user_includes or {}
  for type, include in pairs(user_includes) do
    known_includes[type] = include
  end

  local unique_includes = {}
  local function collect_types(node)
    if node:type() == 'qualified_identifier' then
      local type = get_node_text(node)

      -- Remove template part
      -- i.e. std::vector<int> -> std::vector
      type = remove_template(type)

      local include = known_includes[type]
      if include ~= nil then
        unique_includes[include] = true
      end
    end
  end

  search_down_from_root_until(collect_types)

  local includes = {}
  for include, _ in pairs(unique_includes) do
    table.insert(includes, include)
  end

  M.add_includes(includes)
end

M.get_class_name = function(class_node, buffer)
  buffer = buffer or 0
  for child, name in class_node:iter_children() do
    if name == 'name' then
      return get_node_text(child, buffer)
    end
  end
end

-- Look for a class under the cursor.
-- Return the name as a string
M.get_class_name_under_cursor = function()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local class_node = search_up_until(ts_utils.get_node_at_cursor(), is_class_or_struct)
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
    string.format('%s%s(%s const &) = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s const &) = delete;', indentation, name, name),
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
    string.format('%s%s(%s &&) = delete;', indentation, name, name),
    string.format('%s%s & operator=(%s &&) = delete;', indentation, name, name),
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
  if not vim.fn.bufloaded(buffer) then
    vim.fn.bufload(buffer)
  end

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
  local parameters = search_down_until(function_node, is_parameters)

  if parameters == nil then
    return
  end

  local function remove_default_value(param)
    if param:type() ~= 'optional_parameter_declaration' then
      return get_node_text(param, buffer)
    end

    local text = get_node_text(param, buffer)
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
    if is_parameter(node) then
      local name = search_down_until(node, is_identifier)
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
  search_down_until(parameters, concatenate_params)

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
local function build_function_snippet(info)
  local ls = require('luasnip')
  local fmta = require('luasnip.extras.fmt').fmta
  local sn = ls.snippet_node

  local function_name_node = search_down_until(info.node, is_function_name)
  if function_name_node == nil then
    return
  end
  local function_name = get_node_text(function_name_node, info.buffer)

  -- If there it is a class function, prepend 'ClassName::'
  local surrounding_class_node = search_up_until(info.node, is_class_or_struct)
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
    local snippet = build_function_snippet(info)

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

local function find_not_implemented_functions()
  local declared_functions = {}
  local implemented_functions = {}

  local buffers = { 0, load_alternative_file() }
  for _, buffer in ipairs(buffers) do
    local function collect_functions(node)
      if is_function(node) then
        local name = get_compressed_function_name(node, buffer)
        if is_function_implementation(node) then
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

    search_down_from_root_until(collect_functions, buffer)
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
    local without_implementation = filter_on(find_not_implemented_functions())
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

M.get_snippets_from_not_implemented_functions = function()
  local functions_missing_implementations = find_not_implemented_functions()

  -- Create the actual snippets
  local snip_choices = {}
  for _, f in ipairs(functions_missing_implementations) do
    local _, info = unpack(f)
    local snippet = build_function_snippet(info)

    if snippet ~= nil then
      table.insert(snip_choices, snippet)
    end
  end

  return snip_choices
end

local function find_loop_variable()
  local f = M.get_surrounding_function()
  if f == nil then
    return
  end

  -- Contains the guess for a loop variable
  local guesses = { single = {}, double = {}, best = {} }

  local function store_guess(type, name, iterable_type, primitive_args)
    local guess = { type = type, name = name, iterable_type = iterable_type, primitive_args = primitive_args }
    guesses.best = guess
    guesses[iterable_type] = guess
  end

  local containers = {
    ['std::array'] = 'single',
    ['std::vector'] = 'single',
    ['std::inplace_vector'] = 'single',
    ['std::deque'] = 'single',
    ['std::forward_list'] = 'single',
    ['std::list'] = 'single',
    ['std::set'] = 'single',
    ['std::map'] = 'double',
    ['std::multiset'] = 'single',
    ['std::multimap'] = 'double',
    ['std::unordered_set'] = 'single',
    ['std::unordered_map'] = 'double',
    ['std::unordered_multiset'] = 'single',
    ['std::unordered_multimap'] = 'double',
    ['std::stack'] = '',
    ['std::queue'] = '',
    ['std::priority_queue'] = '',
    ['std::flat_set'] = 'single',
    ['std::flat_map'] = 'double',
    ['std::flat_multiset'] = 'single',
    ['std::flat_multimap'] = 'double',
    ['std::span'] = 'single',
    ['std::mdspan'] = 'single',
  }

  local function get_iterable_type(type_string)
    type_string = remove_template(type_string)
    return containers[type_string] or ''
  end

  local function parse_parameters(node)
    if is_parameter(node) then
      local type_node = node:field('type')[1]
      local typename = get_node_text(type_node)
      local iterable_type = get_iterable_type(typename)
      if iterable_type == '' then
        return false
      end
      local identifier = get_node_text(node:field('declarator')[1])

      -- Save it to guesses
      store_guess(typename, identifier, iterable_type, are_all_template_args_primitive(type_node))
    end
  end

  -- The first row that we can get variables to loop over from
  local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local function look_for_loop_types(node)
    if get_row(node) >= cursor_row then
      return true
    end

    if node:type() == 'parameter_list' then
      search_down_until(node, parse_parameters)
    elseif node:type() == 'declaration' then
      local type_node = node:field('type')[1]
      local typename = get_node_text(type_node)
      local iterable_type = get_iterable_type(typename)
      if iterable_type == '' then
        return false
      end

      -- One of
      -- std::vector<int> v; // declarator(identifier)
      -- std::vector<int> v = {1, 2, 3}; // declarator(declarator(identifier))
      local declarator = node:field('declarator')[1]
      local identifier = ''
      if declarator:type() == 'identifier' then
        identifier = get_node_text(declarator)
      else
        local inner_declarator = declarator:field('declarator')[1]
        if inner_declarator:type() == 'identifier' then
          identifier = get_node_text(inner_declarator)
        end
      end

      -- Save it to guesses
      store_guess(typename, identifier, iterable_type, are_all_template_args_primitive(type_node))
    end
  end

  search_down_until(f, look_for_loop_types)

  return guesses
end

local function swap(table, pos1, pos2)
  table[pos1], table[pos2] = table[pos2], table[pos1]
  return table
end

M.get_for_loop_choices_for_snippet = function()
  local ls = require('luasnip')
  local fmta = require('luasnip.extras.fmt').fmta
  local sn = ls.snippet_node
  local i = ls.insert_node
  local c = ls.choice_node
  local extras = require('luasnip.extras')
  local rep = extras.rep
  local variable_guesses = find_loop_variable()
  local single_name = 'container'
  local single_type = 'auto const&'
  local double_name = 'map'
  local double_type = 'auto const&'

  -- Check the names of the variables
  if variable_guesses ~= nil and not vim.tbl_isempty(variable_guesses.best) then
    if not vim.tbl_isempty(variable_guesses.single) then
      single_name = variable_guesses.single.name

      if variable_guesses.single.primitive_args then
        single_type = 'auto'
      end
    end

    if not vim.tbl_isempty(variable_guesses.double) then
      double_name = variable_guesses.double.name

      if variable_guesses.double.primitive_args then
        double_type = 'auto'
      end
    end
  end

  local choices = {
    sn(
      nil,
      fmta( -- Ranged for loop
        [[
          <> <> : <>
        ]],
        { i(1, single_type), i(2, 'element'), i(3, single_name) }
      )
    ),
    sn(
      nil,
      fmta( -- Indexed for loop
        [[
          <> <> = 0; <> << <>; <>++
        ]],
        { i(1, 'size_t'), i(2, 'i'), rep(2), i(3, 'count'), rep(2) }
      )
    ),
    sn(
      nil,
      fmta( -- Get '\n' terminated strings
        [[
          std::string <>; std::getline(<>, <>);
        ]],
        { i(1, 'line'), i(2, 'std::cin'), rep(1) }
      )
    ),
    sn(
      nil,
      fmta( -- Iterate over map
        [[
          <> [<>, <>] : <>
        ]],
        { i(1, double_type), i(2, 'key'), i(3, 'value'), i(4, double_name) }
      )
    ),
  }

  if variable_guesses ~= nil and not vim.tbl_isempty(variable_guesses.best) then
    if variable_guesses.best.iterable_type == 'double' then
      -- Best guess is a map, iterate over map
      swap(choices, 1, #choices)
    end
  end

  return sn(nil, c(1, choices))
end

-- vim.keymap.set('n', '<leader>gro', find_loop_variable, { buffer = true })

return M
