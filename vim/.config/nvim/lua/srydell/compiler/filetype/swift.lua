local actions = require('xcodebuild.actions')
local xcode_dap = require('xcodebuild.integrations.dap')
local constants = require('srydell.constants')

local function get_compilers()
  return {
    {
      name = 'ios ' .. constants.icons.building,
      tasks = {
        {
          task = 'lua function',
          f = function()
            actions.build_and_run()
            return true
          end,
        },
      },
    },
    {
      name = 'ios ' .. constants.icons.debugging,
      tasks = {
        {
          task = 'lua function',
          f = function()
            xcode_dap.build_and_debug()
            return true
          end,
        },
      },
    },
  }
end

return get_compilers()
