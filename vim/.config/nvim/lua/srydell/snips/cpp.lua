local M = {}

local cpp_ts = require('srydell.treesitter.cpp')
local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
-- local fmt = require('luasnip.extras.fmt').fmt
local sn = ls.snippet_node
local i = ls.insert_node
local c = ls.choice_node
local extras = require('luasnip.extras')
local rep = extras.rep
local t = ls.text_node
local d = ls.dynamic_node
local r = ls.restore_node

M.get_snippets_from_not_implemented_functions = function()
  local functions_missing_implementations = cpp_ts.find_not_implemented_functions()

  -- Create the actual snippets
  local snip_choices = {}
  for _, f in ipairs(functions_missing_implementations) do
    local _, info = unpack(f)
    local snippet = cpp_ts.build_function_snippet(info)

    if snippet ~= nil then
      table.insert(snip_choices, snippet)
    end
  end

  return snip_choices
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

local function find_loop_variable()
  local f = cpp_ts.get_surrounding_function()
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
    type_string = cpp_ts.remove_template(type_string)
    return containers[type_string] or ''
  end

  local function parse_parameters(node)
    if cpp_ts.is_parameter(node) then
      local type_node = node:field('type')[1]
      local typename = cpp_ts.get_node_text(type_node)
      local iterable_type = get_iterable_type(typename)
      if iterable_type == '' then
        return false
      end
      local identifier = cpp_ts.get_node_text(node:field('declarator')[1])

      -- Save it to guesses
      store_guess(typename, identifier, iterable_type, are_all_template_args_primitive(type_node))
    end
  end

  -- The first row that we can get variables to loop over from
  local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local function look_for_loop_types(node)
    if cpp_ts.get_row(node) >= cursor_row then
      return true
    end

    if node:type() == 'parameter_list' then
      cpp_ts.search_down_until(node, parse_parameters)
    elseif node:type() == 'declaration' then
      local type_node = node:field('type')[1]
      local typename = cpp_ts.get_node_text(type_node)
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
        identifier = cpp_ts.get_node_text(declarator)
      else
        local inner_declarator = declarator:field('declarator')[1]
        if inner_declarator:type() == 'identifier' then
          identifier = cpp_ts.get_node_text(inner_declarator)
        end
      end

      -- Save it to guesses
      store_guess(typename, identifier, iterable_type, are_all_template_args_primitive(type_node))
    end
  end

  cpp_ts.search_down_until(f, look_for_loop_types)

  return guesses
end

local function swap(table, pos1, pos2)
  table[pos1], table[pos2] = table[pos2], table[pos1]
  return table
end

M.get_for_loop_choices_for_snippet = function()
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

-- In a header file -> ';'
-- In a source file -> ' {\n<indent>\n}'
local function get_definition_or_declaration()
  local extension = vim.fn.expand('%:e')
  if extension == 'h' or extension == 'hpp' then
    return sn(nil, { t(';') })
  end
  return sn(
    nil,
    fmta(' ' .. [[
        {
          <>
        }
      ]], {
      i(1),
    })
  )
end

M.get_function_snippet = function()
  local functions = {}
  local add_simple_function = true
  if cpp_ts.get_surrounding_argument_list() ~= nil then
    -- Lambda only possible
    add_simple_function = false
    functions = {
      sn(
        nil,
        fmta(
          [[
            [<>](<>) { <> }
          ]],
          { i(1), i(2), i(3) }
        )
      ),
    }
  elseif cpp_ts.get_surrounding_function() ~= nil then
    -- Lambda only possible
    add_simple_function = false
    functions = {
      sn(
        nil,
        fmta(
          [[
            auto <> = [<>](<>) {
              <>
            };
          ]],
          { r(1, 'function_name'), i(2), i(3), i(0) }
        )
      ),
    }
  elseif cpp_ts.get_class_name_under_cursor() == nil then
    functions = M.get_snippets_from_not_implemented_functions()
  end

  if add_simple_function then
    -- A simple function
    table.insert(
      functions,
      sn(
        nil,
        fmta(
          [[
            <> <>(<>)<>
          ]],
          {
            i(1, 'void'),
            r(2, 'function_name'),
            i(3),
            d(4, get_definition_or_declaration),
          }
        )
      )
    )
  end

  return sn(nil, c(1, functions))
end

M.get_enum_choice_snippet = function()
  local enum = cpp_ts.find_enum_from_type()
  if enum == nil then
    return sn(
      nil,
      fmta(
        [[
          case <>: {
            <>
          }
        ]],
        { i(1, '0'), i(2, 'return;') }
      )
    )
  end

  local cases = {}
  local nodes = {}
  for index, value in ipairs(enum.values) do
    table.insert(
      cases,
      string.format(
        [[
case %s::%s: {
  <>
}]],
        enum.name,
        value
      )
    )

    table.insert(nodes, i(index, 'return;'))
  end

  return sn(nil, fmta(table.concat(cases, '\n'), nodes))
end

M.get_operator = function(_, snip)
  -- Not including new/delete/co_await
  local operators = require('srydell.data.cpp_operators')
  local snippet = operators[snip.captures[1]]
  if snippet ~= nil then
    return snippet
  end
  return sn(
    nil,
    fmta(
      string.format(
        [[
          <> operator %s(<>)
          {
            <>
          }
        ]],
        snip.captures[1]
      ),
      {
        i(1),
        i(2),
        i(3),
      }
    )
  )
end

return M
