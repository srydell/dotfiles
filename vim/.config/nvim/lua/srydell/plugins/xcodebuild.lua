return {
  'wojciech-kulik/xcodebuild.nvim',
  ft = 'swift',
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

    local function set_mappings(bufnr)
      local function map(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map('<leader>xl', '<cmd>XcodebuildToggleLogs<cr>', 'Toggle Xcodebuild Logs')
      map('<leader>xb', '<cmd>XcodebuildBuild<cr>', 'Build Project')
      map('<leader>xr', '<cmd>XcodebuildBuildRun<cr>', 'Build & Run Project')
      map('<leader>xt', '<cmd>XcodebuildTest<cr>', 'Run Tests')
      map('<leader>xT', '<cmd>XcodebuildTestClass<cr>', 'Run This Test Class')
      map('<leader>X', '<cmd>XcodebuildPicker<cr>', 'Show All Xcodebuild Actions')
      map('<leader>xd', '<cmd>XcodebuildSelectDevice<cr>', 'Select Device')
      map('<leader>xp', '<cmd>XcodebuildSelectTestPlan<cr>', 'Select Test Plan')
    end

    -- The FileType event that loads this plugin has already fired for the
    -- current buffer, so map it explicitly before handling later buffers.
    if vim.bo.filetype == 'swift' then
      set_mappings(vim.api.nvim_get_current_buf())
    end
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('srydell_xcodebuild_mappings', { clear = true }),
      pattern = 'swift',
      callback = function(event)
        set_mappings(event.buf)
      end,
    })
  end,
}
