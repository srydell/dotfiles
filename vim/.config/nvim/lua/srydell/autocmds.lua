require('srydell.autocmds.indentation')
require('srydell.autocmds.swift')
require('srydell.autocmds.cpp')

local srydell_misc_augroup = vim.api.nvim_create_augroup('srydell_misc_augroup', { clear = false })

-- Disable undo file when in tmp
-- (so no passwords are accidentally saved in undodir)
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = '/tmp/*',
  group = srydell_misc_augroup,
  callback = function()
    vim.opt_local.undofile = false
  end,
})
