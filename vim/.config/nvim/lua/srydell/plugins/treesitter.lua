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
        'cmake',
        'cpp',
        'elixir',
        'heex',
        'html',
        'java',
        'javascript',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'scheme',
        'swift',
        'vim',
        'vimdoc',
      },
      sync_install = false,
      highlight = { enable = true },
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { 'BufWrite', 'CursorHold' },
      },
      -- indent = { enable = true },
    })
  end,
}
