local M = {}

--
-- Return the table with strings splitting input string str by input string delimiter
--
-- E.g.
-- INPUT:
--   str = 'simryd/code/histogram.hpp'
--   val = '/'
-- OUTPUT:
--   { 'simryd', 'code', 'histogram.hpp' }
--
M.split = function(text, delimiter)
  -- This would result in endless loops
  if string.find('', delimiter, 1) then
    return {}
  end

  local split_list = {}
  local position = 1
  while 1 do
    local first, last = string.find(text, delimiter, position)
    if first then
      -- found?
      table.insert(split_list, string.sub(text, position, first - 1))
      position = last + 1
    else
      table.insert(split_list, string.sub(text, position))
      break
    end
  end
  return split_list
end

--
-- Return true if input table tbl contains value val
--
-- E.g.
-- INPUT:
--   tbl = { 'simryd', 'code', 'histogram.hpp' }
--   val = 'code'
-- OUTPUT:
--   true
--
M.contains = function(tbl, val)
  for i = 1, #tbl do
    if tbl[i] == val then
      return true
    end
  end
  return false
end

--
-- Get some project information related to a path
--
-- E.g.
-- INPUT:
--   path = { 'Users', 'simryd', 'code', 'dsf', 'src', 'util', 'perf', 'histogram.hpp' }
-- OUTPUT:
--   {
--     name = 'dsf',
--     path = { 'util', 'perf', 'histogram.hpp' }
--   }
--
local function get_project_info(path)
  local last_directory = ''
  local name = ''
  local src_path = {}
  local internal_path = false
  for i = 1, #path do
    if name == '' then
      if path[i] == 'src' or path[i] == 'include' or path[i] == 'test' then
        -- The name of the project is the parent directory of the above
        name = last_directory
      end
    end
    last_directory = path[i]

    if internal_path then
      -- Record the paths after any of the special paths
      table.insert(src_path, path[i])
    end

    if name ~= '' then
      internal_path = true
    end
  end

  return {
    name = name,
    path = src_path,
  }
end

M.current_path_contains = function(directory)
  return vim.fn.expand('%:p'):find(directory) ~= nil
end

--
-- Get namespace based on project information
--
-- E.g.
-- INPUT:
--   {
--     name = 'dsf',
--     path = { 'util', 'perf', 'histogram.hpp' }
--   }
-- OUTPUT:
--   'dsf::util::perf'
--
M.get_namespace = function(project_info)
  local ns = { project_info.name }

  for i = 1, #project_info.path - 1 do
    table.insert(ns, project_info.path[i])
  end

  return table.concat(ns, '::')
end

-- Get a C-style include guard based on project information
--
-- E.g.
-- INPUT:
--   {
--     name = 'dsf',
--     path = { 'util', 'perf', 'histogram.hpp' }
--   }
-- OUTPUT:
--   'DSF_UTIL_PERF_HISTOGRAM_HPP'
--
M.get_include_guard = function(project_info)
  local guard = { string.upper(project_info.name) }

  for j = 1, #project_info.path do
    local path = string.gsub(project_info.path[j], '%.', '_')
    table.insert(guard, string.upper(path))
  end

  return table.concat(guard, '_')
end

M.get_project = function()
  return get_project_info(M.split(vim.fn.expand('%:p'), '/'))
end

--
-- Merge two list arrays (use vim.tbl_extend for maps)
--
-- E.g.
-- INPUT:
--   { 'srydell', 'github' },
--   { 'stars', '39' }
-- OUTPUT:
--   { 'srydell', 'github' 'stars', '39' }
--
M.merge = function(l0, l1)
  local l = {}
  for i = 1, #l0 do
    table.insert(l, l0[i])
  end

  for i = 1, #l1 do
    table.insert(l, l1[i])
  end
  return l
end

-- Return the first index with the given value (or nil if not found).
function M.index_of(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

local cachedConfig = {}
local searchedForConfig = {}

function M.find_config(filename)
  if searchedForConfig[filename] then
    return cachedConfig[filename]
  end

  local configs = vim.fn.systemlist({
    'find',
    vim.fn.getcwd(),
    '-maxdepth',
    '2',
    '-iname',
    filename,
    '-not',
    '-path',
    '*/.*/*',
  })
  searchedForConfig[filename] = true

  if vim.v.shell_error ~= 0 then
    return nil
  end

  table.sort(configs, function(a, b)
    return a ~= '' and #a < #b
  end)

  if configs[1] then
    cachedConfig[filename] = string.match(configs[1], '^%s*(.-)%s*$')
  end

  return cachedConfig[filename]
end

function M.ternary(cond, trueStatement, falseStatement)
  if cond then
    return trueStatement
  else
    return falseStatement
  end
end

return M
