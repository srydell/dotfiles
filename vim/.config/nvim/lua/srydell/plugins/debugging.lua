return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'wojciech-kulik/xcodebuild.nvim',
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')
    local xcodebuild = require('xcodebuild.dap')
    local registry = require('mason-registry')
    local breakpoint_db = require('srydell.plugins.debugging.breakpoint_db')

    -- language specific adapters
    local dappython = require('dap-python')
    local my_dapui = require('srydell.plugins.debugging.dapui')
    local dapcpp = require('srydell.plugins.debugging.cpp')
    local dapswift = require('srydell.plugins.debugging.swift')

    my_dapui.setup()

    dapcpp.setup()
    dapswift.setup()
    dappython.setup(registry.get_package('debugpy'):get_install_path() .. '/venv/bin/python')

    breakpoint_db.setup()

    local function debug_map(key, func)
      vim.keymap.set('n', '<leader>d' .. key, func)
    end

    -- Mappings
    -- NOTE: All of them start with <leader>d
    debug_map('c', function()
      if not dap.session() and vim.bo.ft == 'swift' then
        xcodebuild.build_and_debug()
        return
      end
      dap.continue()
    end)

    -- Simple breakpoint
    local function toggle_breakpoint()
      dap.toggle_breakpoint()
      breakpoint_db.store()
    end
    -- Log breakpoint
    local function set_log_breakpoint()
      dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
      breakpoint_db.store()
    end

    -- Shortcuts
    vim.keymap.set('n', '<F10>', dap.step_over)
    vim.keymap.set('n', '<F5>', dap.continue)

    debug_map('b', toggle_breakpoint)
    debug_map('i', dap.step_into)
    debug_map('l', set_log_breakpoint)
    debug_map('o', dap.step_out)
    debug_map('r', dap.run_last)
    debug_map('s', dap.step_over)
    debug_map('t', dapui.toggle)
    debug_map('x', dap.terminate)
  end,
}
