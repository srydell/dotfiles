local M = {}

M.setup = function()
  local dap = require('dap')
  local registry = require('mason-registry')
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
end

return M
