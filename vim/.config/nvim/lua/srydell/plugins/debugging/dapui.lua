local M = {}

-- Shared nvim-dap UI layout and lifecycle. Loaded automatically by
-- debugging.lua when nvim-dap-ui is available.
M.setup = function()
  local dap = require('dap')
  local dapui = require('dapui')
  dapui.setup({
    layouts = {
      {
        elements = {
          {
            id = 'scopes',
            size = 0.75,
          },
          {
            id = 'console',
            size = 0.25,
          },
        },
        position = 'bottom',
        size = 25,
      },
    },
  })

  -- Open dapui on debugging started
  dap.listeners.after.event_initialized['dapui_config'] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated['dapui_config'] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited['dapui_config'] = function()
    dapui.close()
  end

  vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticOk', linehl = '', numhl = '' })
  vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
end

return M
