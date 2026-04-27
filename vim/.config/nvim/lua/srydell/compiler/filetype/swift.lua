local constants = require('srydell.constants')

return function()
  return {
    {
      name = 'ios ' .. constants.icons.building,
      tasks = {
        {
          task = 'lua function',
          f = function()
            local actions = require('xcodebuild.actions')
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
            local xcode_dap = require('xcodebuild.integrations.dap')
            xcode_dap.build_and_debug()
            return true
          end,
        },
      },
    },
  }
end
