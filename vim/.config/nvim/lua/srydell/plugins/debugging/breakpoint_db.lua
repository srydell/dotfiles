local M = {}

local function notify_problem(problem, detail)
  require('srydell.plugins.debugging.util').notify_problem(
    'DAP Breakpoints',
    problem,
    'Fix or remove .nvim/breakpoints.json in the project root, then retry.',
    detail
  )
end

local function decode(content)
  local ok, value = pcall(vim.json.decode, content)
  if not ok or type(value) ~= 'table' then
    notify_problem('The saved breakpoint file is not valid JSON.', ok and 'Expected a JSON object.' or value)
    return nil
  end
  return value
end

function M.store()
  local breakpoints = require('dap.breakpoints')
  local settings = vim.fn.getcwd() .. '/.nvim'
  local breakpoints_fp = settings .. '/breakpoints.json'
  if vim.fn.mkdir(settings, 'p') == 0 and vim.fn.isdirectory(settings) ~= 1 then
    notify_problem('Could not create the project breakpoint directory.', settings)
    return
  end

  local bps = {}
  local breakpoints_handle = io.open(breakpoints_fp, 'r')
  if breakpoints_handle then
    local content = breakpoints_handle:read('*a')
    breakpoints_handle:close()
    if content ~= '' then
      bps = decode(content, breakpoints_fp)
      if not bps then
        return
      end
    end
  end

  local breakpoints_by_buf = breakpoints.get()
  for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
    bps[vim.api.nvim_buf_get_name(bufrn)] = breakpoints_by_buf[bufrn]
  end

  local fp = io.open(breakpoints_fp, 'w')
  if not fp then
    notify_problem('Could not open the breakpoint file for writing.', breakpoints_fp)
    return
  end
  fp:write(vim.json.encode(bps))
  fp:close()
end

function M.load()
  local breakpoints = require('dap.breakpoints')
  local settings = vim.fn.getcwd() .. '/.nvim'

  local fp = io.open(settings .. '/breakpoints.json', 'r')
  if not fp then
    return
  end

  local content = fp:read('*a')
  fp:close()

  if string.len(content) == 0 then
    return
  end

  local bps = decode(content, settings .. '/breakpoints.json')
  if not bps then
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local file_name = vim.api.nvim_buf_get_name(buf)

    if bps[file_name] then
      for _, bp in pairs(bps[file_name]) do
        local opts = {
          condition = bp.condition,
          log_message = bp.logMessage,
          hit_condition = bp.hitCondition,
        }
        breakpoints.set(opts, tonumber(buf), bp.line)
      end
    end
  end
end

M.setup = function()
  local autogroup = vim.api.nvim_create_augroup('dap-breakpoints', { clear = true })

  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = autogroup,
    pattern = '*',
    once = true,
    callback = function()
      vim.defer_fn(M.load, 500)
    end,
  })
end

return M
