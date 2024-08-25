return {
  'stevearc/oil.nvim',
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local oil = require('oil')

    vim.keymap.set('n', '<leader>O', '<CMD>Oil<CR>', { desc = 'Toggle oil on the current directory' })

    oil.setup()
  end,
}
