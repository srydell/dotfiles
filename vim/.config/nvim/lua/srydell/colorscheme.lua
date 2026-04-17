-- vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.opt.termguicolors = true

local gruvbox = require('gruvbox')

gruvbox.setup({
    transparent_mode = true,
  })

vim.cmd('colorscheme gruvbox')

local function set_blink_highlights()
  vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = '#000000' })
  vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = '#000000', fg = '#504945' })
  vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = '#1d2021' })
end

set_blink_highlights()

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('srydell_blink_colors', { clear = true }),
  callback = set_blink_highlights,
})
