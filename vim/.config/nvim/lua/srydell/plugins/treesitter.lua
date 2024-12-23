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
        'dockerfile',
        'eex',
        'elixir',
        'git_config',
        'git_rebase',
        'gitattributes',
        -- 'gitcommit',
        'gitignore',
        'heex',
        'html',
        'java',
        'javascript',
        'json',
        'json5',
        'lua',
        'markdown',
        'markdown_inline',
        'objc',
        'python',
        'query',
        'rst',
        'scheme',
        'swift',
        'tmux',
        'toml',
        'vim',
        'vimdoc',
        'yaml',
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
