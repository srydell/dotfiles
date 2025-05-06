return {
  'stevearc/oil.nvim',
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local oil = require('oil')
    oil.setup({
      view_options = {
        show_hidden = true,
      },
    })

    vim.keymap.set('n', '<leader>O', oil.open, { desc = 'Toggle oil on the current directory' })
  end,
}
