-- Include-management helpers: parsing/sorting #include blocks, correcting
-- include guards, and scanning the file for types that need an #include
-- added (with a small built-in map of common standard-library types).
local navigation = require('srydell.treesitter.navigation')

local M = {}


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

-- Before: the file's #include block contains any mix of quoted/angle-bracket
-- includes, possibly unsorted.
-- After: the entire contiguous #include block is replaced in place with the
-- same includes grouped and sorted into (own header, same-dir, other
-- internal, external, system), each group alphabetized with a blank line
-- between the internal/external/system groups. Does nothing if code (not
-- just includes/blank lines) is interleaved between includes, or if an
-- alignment-sentinel header is present.
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

  local function append_include(text, node, suffix, extra_lines)
    local include = { text = text, node = node, suffix = suffix, extra_lines = extra_lines }
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

  -- Rows consumed as continuation lines of a multi-line trailing comment
  -- (e.g. a `//` comment explaining an include that wraps onto the next
  -- line). These are attached to the preceding include's extra_lines rather
  -- than being treated as stray code between includes.
  local consumed_rows = {}

  local has_alignment_header = false
  local function collect_include(node)
    if node:type() == 'preproc_include' then
      for child, name in node:iter_children() do
        if name ~= nil and name == 'path' then
          local text = navigation.get_node_text(child, 0)
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

          -- A trailing `//` comment may continue onto the following lines
          -- (e.g. indented to line up with the comment above). Consume those
          -- lines here so they travel with this include instead of being
          -- mistaken for code between includes.
          local extra_lines = {}
          local next_row = row + 1
          while true do
            local candidate = vim.api.nvim_buf_get_lines(0, next_row, next_row + 1, false)[1]
            if candidate == nil or candidate:match('^%s*//') == nil then
              break
            end
            table.insert(extra_lines, candidate)
            consumed_rows[next_row] = true
            locations.end_row = math.max(next_row, locations.end_row)
            next_row = next_row + 1
          end

          append_include(text, child, suffix, extra_lines)
        end
      end
    end
    -- Do not stop the search
    return false
  end

  navigation.search_down_from_root_until(collect_include)

  if has_alignment_header then
    return
  end

  -- No includes
  if locations.start_row == nil or locations.end_row == nil then
    return
  end

  -- If code is found between the includes
  -- -> give up
  for row = locations.start_row, locations.end_row - 1 do
    if not consumed_rows[row] then
      local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
      if line:match('^%s*$') == nil and line:find('^%s*#%s*include%s+') == nil then
        return
      end
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
      for _, extra_line in ipairs(include.extra_lines or {}) do
        table.insert(lines, extra_line)
      end
    end
  end

  -- Pop the first newline
  if not vim.tbl_isempty(lines) and lines[1] == '' then
    table.remove(lines, 1)
  end

  -- Replace the current include block with the new one
  vim.api.nvim_buf_set_lines(0, locations.start_row, locations.end_row + 1, true, lines)
end

-- Before: the file has a conventional `#ifndef X / #define X ... #endif //
-- X` include guard (possibly preceded by license comments).
-- After: `X` is replaced everywhere it appears in the guard (ifndef, define,
-- and the matching endif comment) with the project's canonical guard name.
-- Does nothing if no conventional guard is found.
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

-- Before: `includes` is a list like `{ '<atomic>', '"foo.h"' }`.
-- After: any of those not already present at the file's effective top level
-- are inserted as new `#include` lines right after the file's preamble
-- (guard/pragma once/license comments), then M.divide_and_sort_includes is
-- expected to tidy them on save. Does nothing if every include is already
-- present.
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
          local row = navigation.get_row(node)
          if depths[row + 1] == guard.depth then
            existing_includes[navigation.get_node_text(child, 0)] = true
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

  navigation.search_down_from_root_until(collect_include)

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

-- Before: the file uses standard-library types (e.g. `std::vector`,
-- `std::atomic`) whose headers may not yet be included.
-- After: calls M.add_includes with the headers for every recognized type
-- found in the file that isn't already covered, merging in `user_includes`
-- as extra type->header mappings. Does nothing (no buffer change) if every
-- type used is already covered.
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
          name = navigation.get_node_text(node),
          node = node,
          scope = import_scope(node:parent()),
        })
      elseif capture == 'using.symbol' then
        table.insert(imports, {
          kind = 'symbol',
          name = navigation.get_node_text(node),
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
            name = navigation.get_node_text(name_nodes[1]),
            target = navigation.get_node_text(target),
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
        local qualified_name = resolve_aliases(M.remove_template(navigation.get_node_text(candidate)), candidate)
        if qualified_name ~= nil then
          add_include_for(qualified_name)
        end
      else
        local short_name = navigation.get_node_text(candidate)
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

return M
