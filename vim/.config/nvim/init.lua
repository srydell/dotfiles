-- Set <leader>
-- Needed before creating mappings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw since using nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.cmd('source ~/.vim/vimrc')

require('packages')
require('mappings')
require('options')
require('colorscheme')
require('globals')
require('lsp')
