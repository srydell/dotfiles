-- Constructor/destructor "definer" generators: creating an in-class
-- declaration/implementation, or - when called outside a class body in a
-- .cpp file - offering a choice snippet built from the not-yet-implemented
-- constructors/destructors declared in the corresponding header.
local navigation = require('srydell.treesitter.navigation')
local predicates = require('srydell.treesitter.cpp.predicates')
local class_info = require('srydell.treesitter.cpp.class_info')
local function_signature = require('srydell.treesitter.cpp.function_signature')

local M = {}

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
  local parameters = navigation.search_down_until(function_node, predicates.is_parameters)

  if parameters == nil then
    return
  end

  local function remove_default_value(param)
    if param:type() ~= 'optional_parameter_declaration' then
      return navigation.get_node_text(param, buffer)
    end

    local text = navigation.get_node_text(param, buffer)
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
    if predicates.is_parameter(node) then
      local name = navigation.search_down_until(node, predicates.is_identifier)
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
  navigation.search_down_until(parameters, concatenate_params)

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

  local function_name_node = navigation.search_down_until(info.node, predicates.is_function_name)
  if function_name_node == nil then
    return
  end
  local function_name = navigation.get_node_text(function_name_node, info.buffer)

  -- If there it is a class function, prepend 'ClassName::'
  local surrounding_class_node = navigation.search_up_until(info.node, predicates.is_class_or_struct)
  if surrounding_class_node ~= nil then
    function_name = class_info.get_class_name(surrounding_class_node, info.buffer) .. '::' .. function_name
  end

  local param_snippet = build_parameter_snippet(info.node, info.buffer)
  if param_snippet == nil then
    return
  end

  local return_type = function_signature.get_function_return_for_snippet(info.node, info.buffer)
  local qualifiers = function_signature.get_function_qualifiers_for_snippet(info.node, info.buffer)

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
      if predicates.is_function(node) then
        local name = function_signature.get_compressed_function_name(node, buffer)
        if predicates.is_function_implementation(node) then
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

    navigation.search_down_from_root_until(collect_functions, buffer)
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
  local indentation = class_info.get_indentation()
  if #indentation == 0 then
    -- Default guess
    indentation = string.rep(' ', vim.opt.shiftwidth:get())
  end

  local extension = vim.fn.expand('%:e')
  local is_source = extension == 'cpp' or extension == 'cxx'
  local class_name = class_info.get_class_name_under_cursor()
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
