-- Shared, point-of-use diagnostics for the nvim-dap configuration.
local M = {}

function M.format_problem(problem, remedy, detail)
  local message = problem
  if detail and detail ~= '' then
    message = message .. '\n\nDetails:\n' .. detail
  end
  if remedy and remedy ~= '' then
    message = message .. '\n\nHow to fix it:\n' .. remedy
  end
  return message
end

function M.notify_problem(title, problem, remedy, detail, level)
  vim.notify(M.format_problem(problem, remedy, detail), level or vim.log.levels.ERROR, { title = title })
end

function M.require_executable(command, title, remedy)
  local path = vim.fn.exepath(command)
  if path ~= '' then
    return path
  end
  M.notify_problem(title, ("Required executable '%s' is not available in Neovim's PATH."):format(command), remedy)
end

return M
