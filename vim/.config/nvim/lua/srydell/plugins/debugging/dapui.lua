local M = {}

M.setup = function()
  local dap = require('dap')
  local dapui = require('dapui')
  dapui.setup({
    layouts = {
      {
        elements = {
          {
            id = 'watches',
            size = 0.5,
          },
          {
            id = 'repl',
            size = 0.5,
          },
        },
        position = 'left',
        size = 40,
      },
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

  -- Disables annoying warning that requires hitting enter
  local orig_notify = require('dap.utils').notify
  require('dap.utils').notify = function(msg, log_level)
    if not string.find(msg, 'Either the adapter is slow') then
      orig_notify(msg, log_level)
    end
  end

  vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
  vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticOk', linehl = '', numhl = '' })
  vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
end

return M
