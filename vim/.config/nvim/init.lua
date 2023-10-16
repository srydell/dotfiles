-- Set <leader>
-- Needed before creating mappings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.cmd('source ~/.vim/vimrc')

require('packages')

require('mappings')
require('options')
require('colorscheme')
require('globals')
require('lsp')
