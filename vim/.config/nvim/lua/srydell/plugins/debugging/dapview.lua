local M = {}

-- Shared nvim-dap UI setup. Loaded by debugging.lua.
M.setup = function()
  require('dap-view').setup({
    winbar = {
      sections = { 'scopes', 'watches', 'breakpoints', 'threads', 'repl' },
      default_section = 'scopes',
    },
    windows = {
      -- A value below 1 is a fraction of the editor height
      size = 0.5,
      position = 'below',
      terminal = { position = 'right' },
    },
    -- Open when a session starts, close when all sessions finish
    auto_toggle = true,
    virtual_text = { enabled = true },
  })

  vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticOk', linehl = '', numhl = '' })
  vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
end

return M
