local actions = require('xcodebuild.actions')
local xcode_dap = require('xcodebuild.integrations.dap')
local constants = require('srydell.constants')

local function get_compilers()
  return {
    {
      name = 'ios ' .. constants.icons.building,
      tasks = function()
        actions.build_and_run()
        vim.cmd('LspRestart')
      end,
      type = 'function',
    },
    {
      name = 'ios ' .. constants.icons.debugging,
      tasks = function()
        xcode_dap.build_and_debug()
        vim.cmd('LspRestart')
      end,
      type = 'function',
    },
  }
end

return get_compilers()
