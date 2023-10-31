M = {}
M.split = function(str, delimiter)
  local result = {};
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end

  return result;
end

M.contains = function(table, val)
   for i=1,#table do
      if table[i] == val then
         return true
      end
   end
   return false
end

-- Get some project information related to a path
--
-- E.g.
-- INPUT:
--   path = {'Users', 'simryd', 'code', 'dsf', 'src', 'util', 'perf', 'histogram.hpp'}
-- OUTPUT:
--   {
--     name = 'dsf',
--     path = { 'util', 'perf', 'histogram.hpp' }
--   }
M.get_project_info = function(path)
  local last_directory = ''
  local name = nil
  local src_path = {}
  local internal_path = false
  for i=1,#path do
    if path[i] == 'src' or path[i] == 'include' then
      name = last_directory
    end
    last_directory = path[i]

    if internal_path then
      table.insert(src_path, path[i])
    end

    if name then
      internal_path = true
    end
  end

  return {
    name = name,
    path = src_path
  }
end

M.get_project = function()
  return M.get_project_info(M.split(vim.fn.expand('%:p'), '/'))
end


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

  for i=1,#project_info.path-1 do
    table.insert(ns, project_info.path[i])
  end

  return table.concat(ns, '::')
end


return M
