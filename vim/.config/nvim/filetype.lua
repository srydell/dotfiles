-- if vim.fn.did_filetype() then
--   return
-- end

local filetype_detect = vim.api.nvim_create_augroup('filetype_detect', { clear = false })

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.txt',
  group = filetype_detect,
  callback = function()
    local util = require('srydell.util')
    local project = util.get_project()

    if project.name == 'dsf' then
      vim.cmd('set filetype=json5')
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = 'wscript',
  group = filetype_detect,
  callback = function()
    vim.cmd('set filetype=python')
  end,
})
