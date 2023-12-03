-- local xcodebuild = require('xcodebuild')

-- vim.keymap.set('n', '<leader>xl', '<cmd>XcodebuildToggleLogs<cr>', { desc = 'Toggle Xcodebuild Logs' })
-- vim.keymap.set('n', '<leader>xb', '<cmd>XcodebuildBuild<cr>', { desc = 'Build Project' })
-- vim.keymap.set('n', '<leader>xr', '<cmd>XcodebuildBuildRun<cr>', { desc = 'Build & Run Project' })
-- vim.keymap.set('n', '<leader>xt', '<cmd>XcodebuildTest<cr>', { desc = 'Run Tests' })
-- vim.keymap.set('n', '<leader>xT', '<cmd>XcodebuildTestClass<cr>', { desc = 'Run This Test Class' })
-- vim.keymap.set('n', '<leader>X', '<cmd>XcodebuildPicker<cr>', { desc = 'Show All Xcodebuild Actions' })
-- vim.keymap.set('n', '<leader>xd', '<cmd>XcodebuildSelectDevice<cr>', { desc = 'Select Device' })
-- vim.keymap.set('n', '<leader>xp', '<cmd>XcodebuildSelectTestPlan<cr>', { desc = 'Select Test Plan' })

local actions = require('xcodebuild.actions')
local xcode_dap = require('xcodebuild.dap')

local function get_compilers()
  return {
    { name = 'ios 🔨', tasks = actions.build_and_run, type = 'function' },
    { name = 'ios 🐛', tasks = xcode_dap.build_and_debug, type = 'function' },
  }
end

return get_compilers()
