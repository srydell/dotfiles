return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'wojciech-kulik/xcodebuild.nvim',
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')
    local breakpoint_db = require('srydell.plugins.debugging.breakpoint_db')

    -- language specific adapters
    local dap_python = require('dap-python')
    local dap_cpp = require('srydell.plugins.debugging.cpp')
    local dap_swift = require('srydell.plugins.debugging.swift')
    local dap_bash = require('srydell.plugins.debugging.bash')

    -- UI
    local my_dapui = require('srydell.plugins.debugging.dapui')

    my_dapui.setup()

    dap_cpp.setup()
    dap_swift.setup()
    dap_bash.setup()
    dap_python.setup()

    breakpoint_db.setup()

    local function debug_map(key, func)
      vim.keymap.set('n', '<leader>d' .. key, func)
    end

    -- Mappings
    -- NOTE: All of them start with <leader>d
    debug_map('c', function()
      if not dap.session() and vim.bo.ft == 'swift' then
        require('xcodebuild.integrations.dap').build_and_debug()
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
    vim.keymap.set('n', '<F11>', dap.step_into)
    vim.keymap.set('n', '<F10>', dap.step_over)
    vim.keymap.set('n', '<F9>', toggle_breakpoint)
    vim.keymap.set('n', '<F5>', dap.continue)

    local function terminate_debug_session()
      if dap.session() then
        dap.terminate()
      end
      require('xcodebuild.actions').cancel()
      require('dapui').close()
    end

    debug_map('b', toggle_breakpoint)
    debug_map('i', dap.step_into)
    debug_map('l', set_log_breakpoint)
    debug_map('o', dap.step_out)
    debug_map('r', dap.run_last)
    debug_map('s', dap.step_over)
    debug_map('t', dapui.toggle)
    debug_map('u', dap.up)
    debug_map('d', dap.down)
    debug_map('x', terminate_debug_session)
  end,
}
