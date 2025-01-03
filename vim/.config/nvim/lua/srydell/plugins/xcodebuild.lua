return {
  'wojciech-kulik/xcodebuild.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('xcodebuild').setup({
      oil_nvim = {
        enabled = true, -- enable updating Xcode project files when using oil.nvim
        guess_target = true, -- guess target for the new file based on the file path
        should_update_project = function(_) -- argument path can lead to directory or file
          -- it could be useful if you mix Xcode project with SPM for example
          return true
        end,
      },
      logs = {
        auto_open_on_success_tests = false,
        auto_open_on_failed_tests = false,
        auto_open_on_success_build = false,
        auto_open_on_failed_build = false,
        auto_focus = false,
        auto_close_on_app_launch = true,
      },
    })

    vim.keymap.set(
      'n',
      '<leader>xl',
      '<cmd>XcodebuildToggleLogs<cr>',
      { desc = 'Toggle Xcodebuild Logs', buffer = true }
    )
    vim.keymap.set('n', '<leader>xb', '<cmd>XcodebuildBuild<cr>', { desc = 'Build Project', buffer = true })
    vim.keymap.set('n', '<leader>xr', '<cmd>XcodebuildBuildRun<cr>', {
      desc = 'Build & Run Project',
      buffer = true,
    })
    vim.keymap.set('n', '<leader>xt', '<cmd>XcodebuildTest<cr>', { desc = 'Run Tests', buffer = true })
    vim.keymap.set('n', '<leader>xT', '<cmd>XcodebuildTestClass<cr>', {
      desc = 'Run This Test Class',
      buffer = true,
    })
    vim.keymap.set(
      'n',
      '<leader>X',
      '<cmd>XcodebuildPicker<cr>',
      { desc = 'Show All Xcodebuild Actions', buffer = true }
    )
    vim.keymap.set('n', '<leader>xd', '<cmd>XcodebuildSelectDevice<cr>', { desc = 'Select Device', buffer = true })
    vim.keymap.set('n', '<leader>xp', '<cmd>XcodebuildSelectTestPlan<cr>', {
      desc = 'Select Test Plan',
      buffer = true,
    })
  end,
}
