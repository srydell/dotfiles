-- Fuzzy Finder (files, lsp, etc)
return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- Fuzzy Finder Algorithm which requires local dependencies to be built.
    -- Only load if `make` is available. Make sure you have the system
    -- requirements installed.
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      -- NOTE: If you are having trouble with this installation,
      --       refer to the README for telescope-fzf-native for more instructions.
      build = 'make',
      cond = function()
        return vim.fn.executable('make') == 1
      end,
    },
    'nvim-telescope/telescope-ui-select.nvim',
    'nvim-telescope/telescope-dap.nvim',
  },
  config = function()
    local actions = require('telescope.actions')
    local telescope = require('telescope')
    telescope.setup({
      extensions = {
        ['ui-select'] = {},
      },
      defaults = {
        file_ignore_patterns = { 'node_modules', '%.git' },
        path_display = {
          truncate = 1,
        },
        mappings = {
          i = {
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
          },
        },
      },
    })

    -- To get ui-select loaded and working with telescope, you need to call
    -- load_extension, somewhere after setup function:
    telescope.load_extension('ui-select')
    telescope.load_extension('dap')
  end,
}
