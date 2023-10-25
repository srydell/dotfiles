-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration
  'nvim-lua/plenary.nvim',

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', opts = {} },
      { 'williamboman/mason-lspconfig.nvim', opts = {} },

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim', tag = 'legacy', event = 'LspAttach', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      { 'folke/neodev.nvim', opts = {} },
    },
  },

  'srydell/vim-n-out',

  'benmills/vimux',

  -- Move through tmux/vim panes with the same keybindings
  'christoomey/vim-tmux-navigator',

  -- Send code from one pane to another with motions
  'jpalardy/vim-slime',

  -- Fuzzy finder.
  -- NOTE: The fzf binary is installed in .vim/pack/minpac/start/fzf/bin
  'junegunn/fzf',

  -- Tags management
  'ludovicchabant/vim-gutentags',

  -- Reads .editorconfig
  'editorconfig/editorconfig-vim',

  -- Add ftdetect, compiler and other good stuff for elixir
  'elixir-editors/vim-elixir',

  -- Debugging
  'szw/vim-maximizer',

  -- A set of filetype based plugins
  'sheerun/vim-polyglot',

  -- Add syntax highlighting for i3 config files
  'mboughaba/i3config.vim',

  -- Asynchronous wrapper around different grep tools (Use multiple at once)
  'mhinz/vim-grepper',

  -- Colorscheme
  { "ellisonleao/gruvbox.nvim", priority = 1000 },

  -- Add end, fi, endfunction and so on automatically
  'tpope/vim-endwise',

  -- Git commands
  'tpope/vim-fugitive',

  -- Project configuration
  -- (used to find alternate files and some fancy Ultisnips tricks)
  'tpope/vim-projectionist',

  -- Interface for repeating plugin type commands with .
  'tpope/vim-repeat',

  -- Operators used to surround text with character
  'tpope/vim-surround',

  -- Asynchronous Lint Engine
  'w0rp/ale',

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  -- {
  --   'nvim-telescope/telescope.nvim',
  --   branch = '0.1.x',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     -- Fuzzy Finder Algorithm which requires local dependencies to be built.
  --     -- Only load if `make` is available. Make sure you have the system
  --     -- requirements installed.
  --     {
  --       'nvim-telescope/telescope-fzf-native.nvim',
  --       -- NOTE: If you are having trouble with this installation,
  --       --       refer to the README for telescope-fzf-native for more instructions.
  --       build = 'make',
  --       cond = function()
  --         return vim.fn.executable 'make' == 1
  --       end,
  --     },
  --   },
  -- },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },

  require('plugins.cmp'),
  require('plugins.snippets'),
  require('plugins.cmp_git'),
  require('plugins.lualine'),
  require('plugins.nvim_tree'),

  install = {
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { 'gruvbox' },
  },
}, {})
