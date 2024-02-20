local actions = require('xcodebuild.actions')
local xcode_dap = require('xcodebuild.integrations.dap')
local constants = require('srydell.constants')

local function get_compilers()
  return {
    {
      name = 'ios ' .. constants.icons.building,
      tasks = actions.build_and_run,
      type = 'function',
    },
    {
      name = 'ios ' .. constants.icons.debugging,
      tasks = xcode_dap.build_and_debug,
      type = 'function',
    },
  }
end

return get_compilers()
