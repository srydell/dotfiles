local M = {}

-- iOS/Swift configuration for nvim-dap. Loaded automatically by debugging.lua,
-- but only registered on macOS because it depends on Xcode and xcodebuild.nvim.
M.setup = function()
  if vim.uv.os_uname().sysname ~= 'Darwin' then
    return
  end

  local dap = require('dap')
  local debug_util = require('srydell.plugins.debugging.util')

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

  dap.adapters.codelldb_ios = function(callback)
    local codelldb = debug_util.require_executable(
      'codelldb',
      'Swift Debugger',
      'Run :MasonInstall codelldb, wait for installation to finish, and retry.'
    )
    if not codelldb then
      return
    end
    local developer_dir = vim.fn.systemlist({ 'xcode-select', '-p' })[1]
    if vim.v.shell_error ~= 0 or not developer_dir then
      debug_util.notify_problem(
        'Swift Debugger',
        'The active Xcode developer directory could not be determined.',
        'Install Xcode, then run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
      )
      return
    end
    local lldb = developer_dir:gsub('/Developer/?$', '') .. '/SharedFrameworks/LLDB.framework/Versions/A/LLDB'
    if vim.fn.filereadable(lldb) ~= 1 then
      debug_util.notify_problem(
        'Swift Debugger',
        'Xcode was found, but its LLDB framework is missing.',
        'Check the selected Xcode installation with: xcode-select -p',
        lldb
      )
      return
    end
    callback({
      type = 'server',
      port = '${port}',
      executable = {
        command = codelldb,
        args = { '--port', '${port}', '--liblldb', lldb },
      },
    })
  end
end

return M
