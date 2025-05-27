local M = {}

-- Look through conan libs and add gcc libs as well
-- NOTE: Requires fd
local function get_ld_libs()
  local home = os.getenv('HOME')
  local libs = io.popen("fd --case-sensitive --type d '^lib$'" .. home .. '/.conan/data'):read('*a')
  if not libs then
    return ''
  end
  local out = '/opt/rh/gcc-toolset-10/root/usr/lib64:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib64/dyninst:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib/dyninst:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib64:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib:'
    .. home
    .. '/code/dsf/build/debug/lib'

  for lib in libs:gmatch('[^\r\n]+') do
    out = out .. ':' .. lib
  end

  return out
end

M.setup = function()
  local dap = require('dap')

  dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = {
      command = vim.fn.exepath('codelldb'),
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

    -- Debugging inside of a Linux docker container
    {
      name = 'Remote launch',
      type = 'codelldb',
      request = 'launch',
      localRoot = '${workspaceFolder}',
      remoteRoot = '/Users/simryd/code/dsf/',
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      sourceMapPathOverrides = {
        ['.'] = '${workspaceFolder}',
      },
      initCommands = {
        'platform select remote-linux',
        'platform connect connect://localhost:31166',
      },
      targetCreateCommands = function()
        -- Use telescope to find executables
        -- NOTE: Requires fd
        return coroutine.create(function(coro)
          local opts = {}
          pickers
            .new(opts, {
              prompt_title = 'Path to executable',
              finder = finders.new_oneshot_job(
                { 'fd', '--no-ignore', '--type', 'x', '--full-path', './build/debug/bin' },
                {}
              ),
              sorter = conf.generic_sorter(opts),
              attach_mappings = function(prompt_buffer)
                actions.select_default:replace(function()
                  actions.close(prompt_buffer)
                  coroutine.resume(coro, { 'target create ' .. action_state.get_selected_entry()[1] })
                end)
                return true
              end,
            })
            :find()
        end)
      end,
      processCreateCommands = {
        'process launch',
      },
      env = {
        LD_LIBRARY_PATH = get_ld_libs,
      },
    },
  }
end

return M
