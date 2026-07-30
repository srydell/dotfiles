local M = {}

-- Bash configuration for nvim-dap. Loaded automatically by debugging.lua.
M.setup = function()
  local dap = require('dap')
  local debug_util = require('srydell.plugins.debugging.util')
  local bashdb_dir = vim.fn.expand('$MASON') .. '/opt/bashdb'

  dap.adapters.bashdb = function(callback)
    local command = debug_util.require_executable(
      'bash-debug-adapter',
      'Bash Debugger',
      'Run :MasonInstall bash-debug-adapter, wait for installation to finish, and retry.'
    )
    if not command then
      return
    end
    if vim.fn.filereadable(bashdb_dir .. '/bashdb') ~= 1 then
      debug_util.notify_problem(
        'Bash Debugger',
        'bash-debug-adapter is installed, but its bundled bashdb files are missing.',
        'Run :MasonUninstall bash-debug-adapter followed by :MasonInstall bash-debug-adapter.'
      )
      return
    end
    callback({ type = 'executable', command = command })
  end
  dap.configurations.sh = {
    {
      type = 'bashdb',
      request = 'launch',
      name = 'Bash: Launch file',
      program = '${file}',
      cwd = '${fileDirname}',
      pathBashdb = bashdb_dir .. '/bashdb',
      pathBashdbLib = bashdb_dir,
      pathBash = 'bash',
      pathCat = 'cat',
      pathMkfifo = 'mkfifo',
      pathPkill = 'pkill',
      env = {},
      args = {},
    },
  }
end

return M
