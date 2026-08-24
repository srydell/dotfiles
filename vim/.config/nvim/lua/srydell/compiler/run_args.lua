-- Persisted arguments to pass to a binary when it is run or debugged.
--
-- Args are keyed by the executable path (e.g. 'build/bin/foo') rather than by
-- compiler, since e.g. clang/gcc RUN/DEBUG and a cmake target all ultimately
-- produce and run the same executable. This lets args set once apply no
-- matter which of those logically related compilers is currently selected.
--
-- Persisted per project to '<cwd>/.nvim/run_args.json', mirroring
-- srydell.plugins.debugging.breakpoint_db.

local M = {}

local function notify_problem(problem, detail)
  vim.notify(
    'Run args: ' .. problem .. '\nFix or remove .nvim/run_args.json in the project root, then retry.\n' .. (
      detail or ''
    ),
    vim.log.levels.ERROR
  )
end

local function db_path()
  return vim.fn.getcwd() .. '/.nvim/run_args.json'
end

local function decode(content)
  local ok, value = pcall(vim.json.decode, content)
  if not ok or type(value) ~= 'table' then
    notify_problem('The saved run args file is not valid JSON.', ok and 'Expected a JSON object.' or value)
    return nil
  end
  return value
end

local function load_db()
  local fp = io.open(db_path(), 'r')
  if not fp then
    return {}
  end

  local content = fp:read('*a')
  fp:close()

  if string.len(content) == 0 then
    return {}
  end

  return decode(content) or {}
end

local function save_db(db)
  local settings = vim.fn.getcwd() .. '/.nvim'
  if vim.fn.mkdir(settings, 'p') == 0 and vim.fn.isdirectory(settings) ~= 1 then
    notify_problem('Could not create the project run args directory.', settings)
    return
  end

  local fp = io.open(db_path(), 'w')
  if not fp then
    notify_problem('Could not open the run args file for writing.', db_path())
    return
  end
  fp:write(vim.json.encode(db))
  fp:close()
end

-- Returns the persisted args (a list of strings) for `executable`.
-- Returns an empty table if none have been set.
M.get = function(executable)
  if executable == nil then
    return {}
  end

  local db = load_db()
  return db[executable] or {}
end

-- Persist `args` (a list of strings) for `executable`.
M.set = function(executable, args)
  if executable == nil then
    return
  end

  local db = load_db()
  db[executable] = args
  save_db(db)
end

-- Prompt the user to edit the persisted args for `executable`.
M.prompt = function(executable)
  if executable == nil then
    vim.print('No executable to set run args for.')
    return
  end

  local current = table.concat(M.get(executable), ' ')
  vim.ui.input({ prompt = 'Args for ' .. executable .. ': ', default = current }, function(input)
    if input == nil then
      return
    end

    -- Collapse repeated whitespace so e.g. '--hello  hello' doesn't produce
    -- an empty argument between the two words.
    local trimmed = vim.trim(input)
    if trimmed == '' then
      M.set(executable, {})
    else
      M.set(executable, require('srydell.util').split(trimmed, ' +'))
    end
  end)
end

return M
