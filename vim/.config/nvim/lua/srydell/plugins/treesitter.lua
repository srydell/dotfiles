return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = ':TSUpdate',
  config = function()
    local configs = require('nvim-treesitter.configs')

    configs.setup({
      ensure_installed = {
        'c',
        'cpp',
        'python',
        'lua',
        'vim',
        'vimdoc',
        'query',
        'elixir',
        'heex',
        'javascript',
        'html',
      },
      sync_install = false,
      highlight = { enable = true },
      -- indent = { enable = true },
    })
  end,
}
