return {
  'stevearc/oil.nvim',
  opts = {},
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local oil = require('oil')

    -- Toggle visibility of nvim tree
    vim.keymap.set('n', '<leader><leader>t', '<CMD>Oil<CR>', { desc = 'Toggle neovim tree' })

    oil.setup()
  end,
}
