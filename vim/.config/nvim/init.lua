-- Set <leader>
-- Needed before creating mappings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.cmd("set runtimepath^=~/.vim runtimepath+=~/.vim/after")
vim.cmd("let &packpath = &runtimepath")
vim.cmd("source ~/.vim/vimrc")

require("mappings")
require("options")
require("colorscheme")
require("globals")
