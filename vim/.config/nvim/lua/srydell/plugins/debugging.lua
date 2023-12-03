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
    -- language specific adapters
    local registry = require('mason-registry')
    local dappython = require('dap-python')

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
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    dap.configurations.cpp = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          -- Use telescope to find executables
          -- NOTE: Requires fd
          return coroutine.create(function(coro)
            local opts = {}
            pickers
              .new(opts, {
                prompt_title = 'Path to executable',
                finder = finders.new_oneshot_job({ 'fd', '--hidden', '--no-ignore', '--type', 'x' }, {}),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(buffer_number)
                  actions.select_default:replace(function()
                    actions.close(buffer_number)
                    coroutine.resume(coro, action_state.get_selected_entry()[1])
                  end)
                  return true
                end,
              })
              :find()
          end)
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }

    dap.configurations.swift = {
      {
        name = 'iOS App Debugger',
        type = 'codelldb_ios',
        request = 'attach',
        program = xcodebuild.get_program_path,
        -- alternatively, you can wait for the process manually
        -- pid = xcodebuild.wait_for_pid,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        waitFor = true,
      },
    }

    dap.adapters.codelldb_ios = {
      type = 'server',
      port = '13000',
      executable = {
        command = registry.get_package('codelldb'):get_install_path() .. '/codelldb',
        args = {
          '--port',
          '13000',
          '--liblldb',
          -- make sure that this path is correct on your side
          '/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB',
        },
      },
    }

    -- disables annoying warning that requires hitting enter
    local orig_notify = require('dap.utils').notify
    require('dap.utils').notify = function(msg, log_level)
      if not string.find(msg, 'Either the adapter is slow') then
        orig_notify(msg, log_level)
      end
    end

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'GruvboxRedBold', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = 'C', texthl = 'GruvboxYellowBold', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = 'R', texthl = 'GruvboxRedBold', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '➡', texthl = 'GruvboxGreenBold', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = 'L', texthl = 'GruvboxYellowBold', linehl = '', numhl = '' })

    local function debug_map(key, func)
      vim.keymap.set('n', '<leader>d' .. key, func)
    end

    vim.keymap.set('n', '<F10>', dap.step_over)
    vim.keymap.set('n', '<F5>', dap.continue)

    -- Mappings
    -- NOTE: All of them start with <leader>d
    debug_map('c', function()
      if not dap.session() and vim.bo.ft == 'swift' then
        xcodebuild.build_and_debug()
        return
      end
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
    debug_map('x', function()
      dap.terminate()
    end)
  end,
}
