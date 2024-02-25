-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
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
      { 'WhoIsSethDaniel/mason-tool-installer.nvim', opts = {} },

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim', event = 'LspAttach', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      { 'folke/neodev.nvim', opts = { library = { plugins = { 'nvim-dap-ui' }, types = true } } },
    },
  },

  -- Some UI sugar
  {
    'stevearc/dressing.nvim',
    opts = {},
  },

  'srydell/vim-n-out',

  'benmills/vimux',

  -- Move through tmux/vim panes with the same keybindings
  'christoomey/vim-tmux-navigator',

  -- Send code from one pane to another with motions
  'jpalardy/vim-slime',

  -- Tags management
  'ludovicchabant/vim-gutentags',

  -- Add ftdetect, compiler and other good stuff for elixir
  'elixir-editors/vim-elixir',

  -- Add syntax highlighting for i3 config files
  'mboughaba/i3config.vim',

  -- Colorscheme
  { 'ellisonleao/gruvbox.nvim', priority = 1000 },

  -- Add end, fi, endfunction and so on automatically
  'tpope/vim-endwise',

  -- Git commands
  'tpope/vim-fugitive',

  -- Project configuration
  -- used to find alternate files
  'tpope/vim-projectionist',

  -- Interface for repeating plugin type commands with .
  'tpope/vim-repeat',

  -- Operators used to surround text with character
  'tpope/vim-surround',

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Java debugger
  { 'mfussenegger/nvim-jdtls' },

  require('srydell.plugins.cmp'),
  require('srydell.plugins.snippets'),
  require('srydell.plugins.cmp_git'),
  require('srydell.plugins.lualine'),
  require('srydell.plugins.oil'),
  require('srydell.plugins.formatter'),
  require('srydell.plugins.lint'),
  require('srydell.plugins.debugging'),
  require('srydell.plugins.telescope'),
  require('srydell.plugins.treesitter'),
  require('srydell.plugins.overseer'),
  require('srydell.plugins.harpoon'),
  require('srydell.plugins.xcodebuild'),
  require('srydell.plugins.clangd_extensions'),
  require('srydell.plugins.dial'),
  -- require('srydell.plugins.trouble'),

  install = {
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { 'gruvbox' },
  },
}, {})
