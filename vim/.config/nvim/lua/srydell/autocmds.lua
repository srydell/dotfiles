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

-- Let 'q' close overseer task output windows
vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = 'OverseerOutput',
  group = srydell_misc_augroup,
  callback = function(args)
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf, silent = true })
  end,
})

-- Enforce that only one OverseerOutput window is ever open at a time.
vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = srydell_misc_augroup,
  callback = function(args)
    if vim.bo[args.buf].filetype ~= 'OverseerOutput' then
      return
    end
    require('srydell.compiler.output_window').close_duplicates(vim.api.nvim_get_current_win())
  end,
})
