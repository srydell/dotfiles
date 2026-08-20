-- Resolve the compile flags a buffer would actually be built with, by
-- locating and querying a `compile_commands.json` compilation database.
-- Used by srydell.util.struct_layout to feed the real project include
-- paths/defines into the record-layout dump instead of only ever using
-- srydell.compiler.helpers.cpp's hardcoded scratch-file flags.
local cpp_helpers = require('srydell.compiler.helpers.cpp')

local M = {}

-- Search upward from `start_path` for compile_commands.json. If none is
-- found directly, look for a `.clangd` file with a
-- `CompileFlags: { CompilationDatabase: <dir> }` entry (as used e.g. when the
-- database lives under build/debug instead of the project root) and check
-- there instead.
-- Returns the absolute path to compile_commands.json, or nil.
function M.find_database(start_path)
  local direct = vim.fs.find('compile_commands.json', { upward = true, path = start_path })[1]
  if direct then
    return direct
  end

  local clangd_config = vim.fs.find('.clangd', { upward = true, path = start_path })[1]
  if not clangd_config then
    return nil
  end

  local lines = vim.fn.readfile(clangd_config)
  local db_dir
  for _, line in ipairs(lines) do
    db_dir = db_dir or line:match('^%s*CompilationDatabase:%s*(.-)%s*$')
  end
  if not db_dir then
    return nil
  end

  local clangd_dir = vim.fs.dirname(clangd_config)
  local candidate = vim.fs.joinpath(clangd_dir, db_dir, 'compile_commands.json')
  if vim.fn.filereadable(candidate) == 1 then
    return candidate
  end
  return nil
end

function M.load(database_path)
  local ok, contents = pcall(vim.fn.readfile, database_path)
  if not ok then
    return nil
  end
  local ok_decode, entries = pcall(vim.json.decode, table.concat(contents, '\n'))
  if not ok_decode then
    return nil
  end
  return entries
end

local function resolve_entry_file(entry)
  if vim.fn.fnamemodify(entry.file, ':p') == entry.file then
    return entry.file
  end
  return vim.fs.joinpath(entry.directory, entry.file)
end

-- Find the database entry that compiles `filepath`. If none matches exactly
-- (compile_commands.json entries never reference headers directly), fall
-- back to whichever entry's source file shares the longest common directory
-- prefix with `filepath` - i.e. the "nearest" translation unit in the source
-- tree. Its -I/-D flags are normally close enough for headers with no
-- sibling .cpp of their own (e.g. a directory of pure headers), since most
-- projects share one catch-all include root across the whole build. Falls
-- back further to any entry at all if nothing shares a directory.
-- Returns entry, is_exact_match (boolean) or nil, nil (empty database).
function M.find_entry(entries, filepath)
  local normalized_target = vim.fs.normalize(filepath)
  local target_dir_parts = vim.split(vim.fs.dirname(normalized_target), '/', { trimempty = true })

  local best_entry, best_score = nil, -1
  for _, entry in ipairs(entries) do
    local entry_file = vim.fs.normalize(resolve_entry_file(entry))
    if entry_file == normalized_target then
      return entry, true
    end

    local entry_dir_parts = vim.split(vim.fs.dirname(entry_file), '/', { trimempty = true })
    local score = 0
    for i = 1, math.min(#target_dir_parts, #entry_dir_parts) do
      if target_dir_parts[i] ~= entry_dir_parts[i] then
        break
      end
      score = score + 1
    end
    if score > best_score then
      best_score = score
      best_entry = entry
    end
  end
  return best_entry, false
end

-- Turn a compile_commands.json `arguments` entry (or a whitespace-split
-- `command` string, for generators that emit the older single-string form)
-- into flags suitable for our own clang invocation: strip the original
-- compiler executable, the source file itself, `-c`/`-o <out>` (both spaced
-- and `-oFILE` combined, as e.g. waf emits), and silence the project's own
-- warnings-as-errors so an unrelated -Werror can't sink the layout dump.
function M.clean_args(args, entry_file)
  local cleaned = {}
  local skip_next = false
  for i = 2, #args do -- skip args[1], the compiler executable
    local arg = args[i]
    if skip_next then
      skip_next = false
    elseif arg == entry_file then
      -- the source file itself; caller substitutes their own
    elseif arg == '-c' then
      -- no codegen needed, we run -fsyntax-only ourselves
    elseif arg == '-o' then
      skip_next = true
    elseif arg:match('^%-o') then
      -- combined -oFILE
    else
      table.insert(cleaned, arg)
    end
  end
  table.insert(cleaned, '-w')
  return cleaned
end

-- Resolve the flags to use for `filepath`.
-- Returns a table:
--   { flags = {...}, directory = <cwd to run the compiler from>,
--     mode = 'exact' | 'approx' | 'default', entry = <raw db entry or nil> }
-- `mode` is 'default' when no compile_commands.json/.clangd was found or no
-- entry matched anything in the same directory; an info notification is
-- printed in that case so the fallback is not silent.
function M.get_flags(filepath)
  local database_path = M.find_database(vim.fs.dirname(filepath))
  if database_path then
    local entries = M.load(database_path)
    if entries then
      local entry, is_exact = M.find_entry(entries, filepath)
      if entry then
        local args = entry.arguments
        if not args and entry.command then
          args = vim.split(entry.command, '%s+')
        end
        if args and #args > 0 then
          local entry_file = resolve_entry_file(entry)
          local flags = M.clean_args(args, entry.file)
          if not is_exact then
            vim.notify(
              ('No compile_commands.json entry for %s; using flags from %s in the same directory as an approximation.'):format(
                vim.fn.fnamemodify(filepath, ':t'),
                vim.fn.fnamemodify(entry_file, ':t')
              ),
              vim.log.levels.INFO,
              { title = 'Struct Layout' }
            )
          end
          return { flags = flags, directory = entry.directory, mode = is_exact and 'exact' or 'approx', entry = entry }
        end
      end
    end
  end

  vim.notify(
    'No compile_commands.json found (or no matching entry); falling back to default compiler flags.',
    vim.log.levels.INFO,
    { title = 'Struct Layout' }
  )
  return {
    flags = cpp_helpers.get_flags('clang', false),
    directory = vim.fs.dirname(filepath),
    mode = 'default',
    entry = nil,
  }
end

return M
