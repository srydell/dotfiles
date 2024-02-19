local srydell_indentation = vim.api.nvim_create_augroup('srydell_indentation', { clear = false })

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.cpp', '*.hpp', '*.h', '*.swift', '*.lua', '*.txt' },
  group = srydell_indentation,
  callback = function()
    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
    vim.opt.tabstop = 2
  end,
})
