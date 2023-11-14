return {
  'mfussenegger/nvim-dap',
  dependencies = { 'rcarriga/nvim-dap-ui', 'mfussenegger/nvim-dap-python' },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')
    dapui.setup()

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

    -- language specific adapters
    local dappython = require('dap-python')
    dappython.setup('~/.local/share/nvim/mason/packages/debugpy/venv/bin/python')

    local function debug_map(key, func)
      vim.keymap.set('n', '<leader>d' .. key, func)
    end

    -- Mappings
    debug_map('c', function()
      dap.continue()
    end)
    debug_map('s', function()
      dap.step_over()
    end)
    debug_map('i', function()
      dap.step_into()
    end)
    debug_map('o', function()
      dap.step_out()
    end)
    debug_map('b', function()
      dap.toggle_breakpoint()
    end)
    debug_map('r', function()
      dap.run_last()
    end)

    -- vim.keymap.set('n', '<Leader>lp', function()
    --   dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
    -- end)
    -- vim.keymap.set('n', '<Leader>dr', function()
    --   dap.repl.open()
    -- end)
    -- vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
    --   require('dap.ui.widgets').hover()
    -- end)
    -- vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
    --   require('dap.ui.widgets').preview()
    -- end)
    -- vim.keymap.set('n', '<Leader>df', function()
    --   local widgets = require('dap.ui.widgets')
    --   widgets.centered_float(widgets.frames)
    -- end)
    -- vim.keymap.set('n', '<Leader>ds', function()
    --   local widgets = require('dap.ui.widgets')
    --   widgets.centered_float(widgets.scopes)
    -- end)
  end,
}
