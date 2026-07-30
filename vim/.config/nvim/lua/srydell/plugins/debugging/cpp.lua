local M = {}

-- Local and Docker-based C/C++ configurations for nvim-dap. This setup is
-- called automatically from srydell.plugins.debugging when nvim-dap loads.
M.setup = function()
  local dap = require('dap')
  local debug_util = require('srydell.plugins.debugging.util')
  -- This module implements the Docker-specific adapter and interactive launch
  -- flow. debugging.lua calls this setup function when lazy.nvim configures
  -- nvim-dap, so no separate require is needed elsewhere.
  local docker_lldb = require('srydell.plugins.debugging.docker_lldb')

  dap.adapters.codelldb = function(callback)
    local command = debug_util.require_executable(
      'codelldb',
      'C/C++ Debugger',
      'Run :MasonInstall codelldb, wait for installation to finish, and retry.'
    )
    if command then
      callback({ type = 'executable', command = command, detached = false })
    end
  end
  dap.adapters.docker_lldb = docker_lldb.adapter
  vim.api.nvim_create_user_command('DapDockerResetContainer', docker_lldb.reset_container, {
    desc = 'Forget the container selected for Docker LLDB',
  })

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
        if
          not debug_util.require_executable(
            'fd',
            'C/C++ Debugger',
            table.concat({
              'macOS: brew install fd',
              'Arch Linux: sudo pacman -S fd',
              'Then restart Neovim or make sure fd is visible in its PATH.',
            }, '\n')
          )
        then
          return require('dap').ABORT
        end
        return coroutine.create(function(coro)
          local opts = {}
          pickers
            .new(opts, {
              prompt_title = 'Path to executable',
              finder = finders.new_oneshot_job({ 'fd', '--no-ignore', '--type', 'x' }, {}),
              sorter = conf.generic_sorter(opts),
              attach_mappings = function(prompt_buffer)
                actions.select_default:replace(function()
                  actions.close(prompt_buffer)
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

    -- Run lldb-dap inside any local or remote Docker container over stdio.
    -- Container, remote project root, executable, and arguments are resolved
    -- interactively when the configuration is selected.
    {
      name = 'Docker: Launch file',
      type = 'docker_lldb',
      request = 'launch',
      console = 'internalConsole',
      stopOnEntry = false,
      program = docker_lldb.pick_program,
      args = docker_lldb.prompt_arguments,
    },
  }
end

return M
