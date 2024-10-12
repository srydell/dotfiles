M = {}

local function append_header_extensions(base)
  return { base .. '.h', base .. '.hpp' }
end

local function append_source_extensions(base)
  return { base .. '.cpp', base .. '.cxx' }
end

local function is_source()
  local ext = vim.fn.expand('%:e')
  for _, source in ipairs({ 'cpp', 'cxx' }) do
    if ext == source then
      return true
    end
  end

  return false
end

-- Look for an alternative file.
-- (.cpp|.cxx) -> (.h|.hpp)
-- (.h|.hpp)   -> (.cpp|.cxx)
-- Finds first alternative file existing on filesystem.
-- Return nil if no alternative file found.
-- Example:
-- current_file = src/hello.cpp
-- Will check:
-- {
--   src/hello.h,
--   src/hello.hpp,
--   include/hello.h,
--   include/hello.hpp,
--   inc/hello.h,
--   inc/hello.hpp
-- }
--
-- Example:
-- current_file = include/hello.h
-- Will check:
-- {
--   include/hello.cpp,
--   include/hello.cxx,
--   src/hello.cpp,
--   src/hello.cxx,
--   source/hello.cpp,
--   source/hello.cxx,
-- }
M.get_alternative_file = function()
  local exists = vim.fn.filereadable

  local from_dirs = {}
  local to_dirs = {}
  local append_extensions = nil
  if is_source() then
    -- We are a source file,
    -- looking for a header
    from_dirs = { 'src', 'source' }
    to_dirs = { 'include', 'inc' }
    append_extensions = append_header_extensions
  else
    -- We are a header,
    -- looking for a source file
    from_dirs = { 'include', 'inc' }
    to_dirs = { 'src', 'source' }
    append_extensions = append_source_extensions
  end

  local file = nil
  local function set_alt_file(base)
    for _, f in ipairs(append_extensions(base)) do
      if exists(f) then
        file = f
        return true
      end
    end
    return false
  end

  local base = vim.fn.expand('%:p:r')
  -- In the same directory?
  if set_alt_file(base) then
    return file
  end

  -- Is there an source/include directory?
  for _, from in ipairs(from_dirs) do
    for _, to in ipairs(to_dirs) do
      local new_base, count = base:gsub(from, to)
      if count ~= 0 then
        if set_alt_file(new_base) then
          return file
        end
      end
    end
  end

  -- Give up
  return nil
end

M.get_alternative_include_guess = function()
  if not is_source() then
    return ''
  end

  local alt_file = M.get_alternative_file()
  if alt_file == nil then
    return ''
  end

  -- In a best guess order
  for _, include_dir in ipairs({ 'src', 'include', 'source', 'inc' }) do
    local i, j = alt_file:find(include_dir)
    if i ~= nil and j ~= nil then
      -- /Users/me/src/module/hello.cpp -> module/hello.hpp
      return alt_file:sub(j + 2)
    end
  end

  return ''
end

return M
