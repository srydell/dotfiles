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
    local registry = require('mason-registry')

    local dappython = require('dap-python')
    dappython.setup(registry.get_package('debugpy'):get_install_path() .. '/venv/bin/python')

    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = registry.get_package('codelldb'):get_install_path() .. '/codelldb',
        args = { '--port', '${port}' },

        -- On windows you may have to uncomment this:
        -- detached = false,
      },
    }
    dap.configurations.cpp = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }

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
  end,
}
