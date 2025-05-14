local M = {}

M.setup = function()
  local dap = require('dap')
  local registry = require('mason-registry')
  local xcodebuild = require('xcodebuild.integrations.dap')

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
      command = vim.fn.exepath('codelldb'),
      args = {
        '--port',
        '13000',
        '--liblldb',
        -- make sure that this path is correct on your side
        '/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB',
      },
    },
  }
end

return M
