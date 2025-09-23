local filetype_detect = vim.api.nvim_create_augroup('filetype_detect', { clear = false })

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.txt',
  group = filetype_detect,
  callback = function()
    local util = require('srydell.util')

    if util.current_path_contains('dsf') then
      local directory = vim.fn.expand('%:p:h:t')
      if directory == 'test_scenarios' then
        vim.cmd('set filetype=json5')
        return
      end

      local filename = vim.fn.expand('%:p:t')
      if filename:match('log_.+') ~= nil then
        vim.cmd('set filetype=scenario')
      end
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

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.tsan',
  group = filetype_detect,
  callback = function()
    vim.cmd('set filetype=tsan')
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*.json_v1',
  group = filetype_detect,
  callback = function()
    vim.cmd('set filetype=json')
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = 'pom.xml',
  group = filetype_detect,
  callback = function()
    local jdtls = require('srydell.lsp.jdtls')

    jdtls.setup()
  end,
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = 'templates/*.html',
  group = filetype_detect,
  callback = function()
    vim.cmd('set filetype=html.jinja')
  end,
})
