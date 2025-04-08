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
        'gitignore',
        'heex',
        'helm',
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
        'terraform',
        'tmux',
        'toml',
        'vim',
        'vimdoc',
        'yaml',
        -- 'gitcommit',
      },
      sync_install = false,
      highlight = { enable = true },
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { 'BufWrite', 'CursorHold' },
      },
      textobjects = {
        swap = {
          enable = true,
          swap_next = {
            ['<leader>aa'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>aA'] = '@parameter.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            [']m'] = '@function.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
          },
        },
        select = {
          enable = true,

          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,

          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            -- You can optionally set descriptions to the mappings (used in the desc parameter of
            -- nvim_buf_set_keymap) which plugins like which-key display
            ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
          },
        },
      },
      -- indent = { enable = true },
    })

    local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')

    -- Repeat movement with ; and ,
    -- ensure ; goes forward and , goes backward regardless of the last direction
    -- vim way: ; goes to the direction you were moving.
    vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
    vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)

    -- make builtin f, F, t, T also repeatable with ; and ,
    vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}
