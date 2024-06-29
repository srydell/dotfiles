local M = {}

-- Look through conan libs and add gcc libs as well
local function get_ld_libs()
  local libs = io.popen('find ' .. os.getenv('HOME') .. '/.conan/data/ -iname lib')
  if not libs then
    return ''
  end
  local out = '/opt/rh/gcc-toolset-10/root/usr/lib64:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib64/dyninst:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib/dyninst:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib64:'
    .. '/opt/rh/gcc-toolset-10/root/usr/lib:'
    .. os.getenv('HOME')
    .. '/code/dsf/build/debug/lib'

  for lib in libs:lines() do
    out = out .. ':' .. lib
  end

  return out
end

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
                { 'fd', '--hidden', '--no-ignore', '--type', 'x', '--full-path', './build/debug/bin' },
                {}
              ),
              sorter = conf.generic_sorter(opts),
              attach_mappings = function(buffer_number)
                actions.select_default:replace(function()
                  actions.close(buffer_number)
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
