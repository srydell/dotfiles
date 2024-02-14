local filetype_commands = vim.api.nvim_create_augroup('filetype_commands', { clear = false })

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.cpp', '*.hpp', '*.h', '*.swift', '*.lua' },
  group = filetype_commands,
  callback = function()
    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
    vim.opt.tabstop = 2
  end,
})
