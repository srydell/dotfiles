-- Set <leader>
-- Needed before creating mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw since using nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("srydell.packages")
require("srydell.mappings")
require("srydell.options")
require("srydell.colorscheme")
require("srydell.globals")
require("srydell.lsp")
require("srydell.snips.skeleton")
