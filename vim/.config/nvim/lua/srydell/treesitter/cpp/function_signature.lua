-- Helpers for turning a function_declarator node into pieces of C++ source
-- text: cleaned parameter lists, return type, qualifiers (const/noexcept/...),
-- and a "compressed" signature used to compare a declaration against its
-- definition. These are internal building blocks consumed by
-- lua/srydell/treesitter/cpp/definitions.lua and are intentionally not
-- exposed on the public cpp.lua API.
local navigation = require('srydell.treesitter.navigation')
local predicates = require('srydell.treesitter.cpp.predicates')
local class_info = require('srydell.treesitter.cpp.class_info')

local M = {}

-- nvim_buf_get_text returns one array element per line in the range. Joining
-- with a space keeps this safe even when a range happens to span multiple
-- lines (e.g. a wrapped return type or parameter list), instead of silently
-- truncating to whatever `[1]` (the first line) contains.
local function get_buf_text_joined(buffer, start_row, start_col, end_row, end_col)
  local lines = vim.api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col, {})
  return table.concat(lines, ' ')
end

-- Remove any of `words` from `text` as whole words, so stripping e.g. 'final'
-- does not also eat part of an unrelated identifier such as 'finalize'.
local function strip_words(text, words)
  for _, word in ipairs(words) do
    text = text:gsub('%f[%w]' .. word .. '%f[%W]', '')
  end
  return text
end

-- Removes the name and the default parameter values from the parameters.
-- Also removes whitespace to make it easier to compare parameters as strings.
-- I.e. (std::string my_string, int i = 5) -> (std::string,int)
local function clean_params(params_node, buffer)
  buffer = buffer or 0
  local params = '('
  local function concatenate_params(node)
    -- Simple parameter or with a default value
    if predicates.is_parameter(node) then
      -- The whole parameter - e.g. 'std::string const & s = "hi"'
      local name = navigation.search_down_until(node, predicates.is_identifier)
      if name ~= nil then
        local start_row, start_col, _, _ = vim.treesitter.get_node_range(node)
        local _, start_name_col, end_row, _ = vim.treesitter.get_node_range(name)
        -- Remove anything after the name
        -- This includes default parmeters
        local parameter = get_buf_text_joined(buffer, start_row, start_col, end_row, start_name_col)
        params = params .. parameter .. ','
      else
        -- No name parameter
        if node:type() == 'parameter_declaration' then
          -- Take the whole param name
          params = params .. navigation.get_node_text(node, buffer) .. ','
        else
          -- Optional parameter with no name? Yikes.
          -- Remove anything after the '='
          local param_name = navigation.get_node_text(node, buffer)
          param_name = param_name:sub(1, param_name:find('=') - 1)
          params = params .. param_name .. ','
        end
      end
    end
  end

  navigation.search_down_until(params_node, concatenate_params)
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
  local parameters_node = navigation.search_down_until(function_node, predicates.is_parameters)
  if parameters_node == nil then
    return ''
  end

  -- Everything after the parameter node to the end of the function node
  local _, _, end_row, end_col = vim.treesitter.get_node_range(function_node)
  local _, _, start_row, start_col = vim.treesitter.get_node_range(parameters_node)

  local qualifiers = get_buf_text_joined(buffer, start_row, start_col, end_row, end_col)

  -- Remove leading & trailing whitespace
  qualifiers = qualifiers:gsub('^%s*', '')
  qualifiers = qualifiers:gsub('%s*$', '')
  return qualifiers
end

local function remove_declaration_only_qualifiers(qualifiers)
  -- Should not include things that are only in the declaration.
  -- Note: `noexcept` is intentionally NOT stripped here. Unlike
  -- override/final/explicit, it is part of the function's type and must be
  -- repeated on the out-of-class definition or the two will not match.
  qualifiers = strip_words(qualifiers, { 'final', 'override', 'explicit' })

  -- Remove whitespace
  qualifiers = qualifiers:gsub('^%s*', '')
  qualifiers = qualifiers:gsub('%s*$', '')
  return qualifiers
end

M.get_function_qualifiers_for_snippet = function(function_node, buffer)
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
  local function_name_node = navigation.search_down_until(function_node, predicates.is_function_name)

  -- Give up
  if function_name_node == nil then
    return ''
  end

  local function is_function_root(node)
    return node:type() == 'declaration' or node:type() == 'field_declaration' or node:type() == 'function_definition'
  end

  local function_root = navigation.search_up_until(function_node, is_function_root)
  if function_root == nil then
    return ''
  end

  local start_row, start_col, _, _ = vim.treesitter.get_node_range(function_root)
  local _, start_name_col, end_row, _ = vim.treesitter.get_node_range(function_name_node)
  local return_type = get_buf_text_joined(buffer, start_row, start_col, end_row, start_name_col)
  return return_type:gsub('%s+$', '')
end

local function remove_declaration_only_return_qualifiers(return_type)
  -- Should not include things that are only in the declaration.
  -- 'explicit' has no return type of its own; it shows up here because
  -- ctors/dtors have no explicit return type to anchor on otherwise.
  return_type = strip_words(return_type, { 'inline', 'static', 'virtual', 'explicit' })

  -- Remove whitespace
  return_type = return_type:gsub('^%s*', '')
  return_type = return_type:gsub('%s*$', '')
  return return_type
end

M.get_function_return_for_snippet = function(function_node, buffer)
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
M.get_compressed_function_name = function(function_node, buffer)
  buffer = buffer or 0

  local compressed_name = ''

  local class_node = navigation.search_up_until(function_node, predicates.is_class_or_struct)
  local class_prefix = ''
  if class_node ~= nil then
    class_prefix = class_info.get_class_name(class_node, buffer) .. '::'
  end

  for child, _ in function_node:iter_children() do
    -- Name of the function
    if predicates.is_function_name(child) then
      compressed_name = compressed_name .. class_prefix .. navigation.get_node_text(child, buffer)
    end

    if predicates.is_parameters(child) then
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

return M
