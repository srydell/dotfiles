-- Generators that build C++ code from an enum class under the cursor (or,
-- for find_enum_from_type, found via an LSP typeDefinition lookup): a
-- print() overload, a to_string() stringifier, a bitmask-style stringifier,
-- and a bare switch skeleton.
local navigation = require('srydell.treesitter.navigation')

local M = {}

local function is_enum(node)
  return node:type() == 'enum_specifier'
end

local function parse_enum(enum_node, buffer)
  buffer = buffer or 0
  local enum = {}
  for child, name in enum_node:iter_children() do
    if name == 'name' then
      enum[name] = navigation.get_node_text(child, buffer)
    elseif name == 'body' then
      enum['values'] = {}
      for enumerator, _ in child:iter_children() do
        for value, value_name in enumerator:iter_children() do
          if value_name == 'name' then
            table.insert(enum['values'], navigation.get_node_text(value, buffer))
          end
        end
      end
    end
  end
  return enum
end

local function get_enum_under_cursor()
  local enum_node = navigation.search_up_until(navigation.get_node_at_cursor(), is_enum)
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

-- Build one case/if block per enum value using `case_format`, which is given
-- (enum_name, value) and must return the full block of text for that value.
-- Shared by all the M.make_enum_* generators below to avoid re-implementing
-- the same lookup/nil-check/case-loop four times.
local function build_enum_cases(enum, case_format)
  local cases = {}
  for _, value in ipairs(enum.values) do
    table.insert(cases, case_format(enum.name, value))
  end
  return table.concat(cases, '\n')
end

M.make_enum_print = function()
  local enum, node = get_enum_under_cursor()
  if enum == nil then
    return
  end

  local cases = build_enum_cases(enum, function(enum_name, value)
    return string.format(
      [[  case %s::%s: {
    std::cout << "%s::%s" << '\n';
  }]],
      enum_name,
      value,
      enum_name,
      value
    )
  end)

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
    cases,
    enum.name
  )

  navigation.add_text_after(node, enum_printer_function)
end

-- Create a stringify enum switch function over all the cases based on the enum under the cursor
M.make_enum_stringify = function()
  local enum, node = get_enum_under_cursor()
  if enum == nil then
    return
  end

  local cases = build_enum_cases(enum, function(enum_name, value)
    return string.format(
      [[  case %s::%s: {
    return "%s::%s";
  }]],
      enum_name,
      value,
      enum_name,
      value
    )
  end)

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
    cases
  )

  navigation.add_text_after(node, enum_stringify_function)
end

-- Create a binary enum switch function over all the cases based on the enum under the cursor
M.make_enum_binary = function()
  local enum, node = get_enum_under_cursor()
  if enum == nil then
    return
  end

  local cases = build_enum_cases(enum, function(enum_name, value)
    return string.format(
      [[  if ((event & %s::%s) > 0) {
    return "%s::%s";
  }]],
      enum_name,
      value,
      enum_name,
      value
    )
  end)

  local enum_binary_stringify = string.format(
    [[
std::string to_string(uint32_t event) {
%s
  return "Unknown";
}
]],
    cases
  )

  navigation.add_text_after(node, enum_binary_stringify)
end

-- Create a simple enum switch over all the cases based on the enum under the cursor
M.make_enum_switch = function()
  local enum, node = get_enum_under_cursor()
  if enum == nil then
    return
  end

  local cases = build_enum_cases(enum, function(enum_name, value)
    return string.format(
      [[  case %s::%s: {
    return;
  }]],
      enum_name,
      value
    )
  end)

  local enum_switch = string.format(
    [[
  switch (e) {
%s
  }
]],
    cases
  )

  navigation.add_text_after(node, enum_switch)
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
M.find_enum_from_type = function()
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
  if lines[1] == nil then
    -- The reported LSP location does not exist in the buffer (stale index,
    -- out-of-range line, etc.). Bail out instead of erroring on nil.
    return
  end

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

  local enum_node = navigation.search_down_from_root_until(is_our_enum, buffer)
  if enum_node == nil then
    return
  end
  return parse_enum(enum_node, buffer)
end

return M
