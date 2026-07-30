local M = {}

M.setup = function()
  local dap = require('dap')
  -- This module implements the Docker-specific adapter and interactive launch
  -- flow. debugging.lua calls this setup function when lazy.nvim configures
  -- nvim-dap, so no separate require is needed elsewhere.
  local docker_lldb = require('srydell.plugins.debugging.docker_lldb')

  dap.adapters.codelldb = {
    type = 'executable',
    command = 'codelldb', -- or if not in $PATH: "/absolute/path/to/codelldb"

    -- On windows you may have to uncomment this:
    -- detached = false,
  }
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
        -- Use telescope to find executables
        -- NOTE: Requires fd
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
