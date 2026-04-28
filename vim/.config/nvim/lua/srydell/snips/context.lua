local M = {}

-- LuaSnip sees each entry returned from this module as an active snippet
-- filetype. For a regular C++ file this is just { "cpp" }, while project or
-- path-specific contexts append extra scopes such as "cpp_test" or "cpp_dsf".

local function split_filetypes(filetype)
  if filetype == '' then
    return {}
  end

  return vim.split(filetype, '.', { plain = true, trimempty = false })
end

local function get_buf_name(bufnr)
  bufnr = bufnr or 0
  return vim.api.nvim_buf_get_name(bufnr)
end

local function get_project_name(path)
  -- Match the convention already used elsewhere in the config:
  -- <project>/{src,include,test}/...
  local last_directory = ''
  for part in path:gmatch('[^/]+') do
    if part == 'src' or part == 'include' or part == 'test' then
      return last_directory
    end

    last_directory = part
  end
end

local function is_cpp_test_file(path)
  return path:find('/test/', 1, true) ~= nil
    or path:find('/tests/', 1, true) ~= nil
    or path:find('[_%-]test%.%a+$') ~= nil
    or path:find('[_%-]tests%.%a+$') ~= nil
end

local function is_dsf_project(path)
  return get_project_name(path) == 'dsf' or path:find('/dsf/', 1, true) ~= nil
end

function M.filetypes_for_buffer(bufnr)
  bufnr = bufnr or 0

  local filetypes = split_filetypes(vim.bo[bufnr].filetype)
  if not vim.tbl_contains(filetypes, 'cpp') then
    return filetypes
  end

  local path = get_buf_name(bufnr)
  -- These are additive. A DSF test file intentionally gets both cpp_test and
  -- cpp_dsf snippets in addition to the base cpp snippets.
  if is_cpp_test_file(path) then
    table.insert(filetypes, 'cpp_test')
  end

  if is_dsf_project(path) then
    table.insert(filetypes, 'cpp_dsf')
  end

  return filetypes
end

return M
