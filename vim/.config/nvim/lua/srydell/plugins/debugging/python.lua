-- Python configuration for nvim-dap. Loaded automatically by debugging.lua.
-- nvim-dap-python chooses the project interpreter for the debuggee; Mason's
-- debugpy-adapter is only the DAP server and can live in a separate environment.
local M = {}

function M.setup()
  local dap = require('dap')
  local dap_python = require('dap-python')
  local debug_util = require('srydell.plugins.debugging.util')

  dap_python.setup('debugpy-adapter')
  local adapter = dap.adapters.python
  dap.adapters.python = function(callback, config, parent)
    local command = debug_util.require_executable(
      'debugpy-adapter',
      'Python Debugger',
      'Run :MasonInstall debugpy, wait for installation to finish, and retry.'
    )
    if command then
      adapter(callback, config, parent)
    end
  end
  dap.adapters.debugpy = dap.adapters.python
end

return M
