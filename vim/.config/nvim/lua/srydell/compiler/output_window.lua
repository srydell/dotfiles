-- Shared helper for managing windows showing overseer task output
-- (filetype 'OverseerOutput'). Used both by the <leader>o toggle
-- (srydell.plugins.overseer) and by M.run() (srydell.compiler.common) so
-- that starting a new task always clears out stale output windows left
-- over from a previous run, rather than letting them pile up.
local M = {}

M.close_all = function()
  local closed_any = false
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.bo[bufnr].filetype == 'OverseerOutput' then
      vim.api.nvim_win_close(winid, false)
      closed_any = true
    end
  end
  return closed_any
end

return M
