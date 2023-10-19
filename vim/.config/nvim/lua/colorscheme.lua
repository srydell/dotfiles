-- vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.opt.termguicolors = true

local gruvbox = require('gruvbox')

gruvbox.setup({
    transparent_mode = true,
  })

vim.cmd('colorscheme gruvbox')
