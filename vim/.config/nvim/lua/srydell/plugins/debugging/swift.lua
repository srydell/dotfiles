local M = {}

M.setup = function()
  local dap = require('dap')
  local developer_dir = vim.fn.systemlist({ 'xcode-select', '-p' })[1]
  local lldb_path
  if vim.v.shell_error == 0 and developer_dir then
    local xcode_contents = developer_dir:gsub('/Developer/?$', '')
    lldb_path = xcode_contents .. '/SharedFrameworks/LLDB.framework/Versions/A/LLDB'
  end

  dap.configurations.swift = {
    {
      name = 'iOS App Debugger',
      type = 'codelldb_ios',
      request = 'attach',
      -- Resolve the Xcode app path only when starting a Swift session so the
      -- integration remains unloaded while debugging other languages.
      program = function(...)
        return require('xcodebuild.integrations.dap').get_program_path(...)
      end,
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
        lldb_path or 'liblldb',
      },
    },
  }
end

return M
