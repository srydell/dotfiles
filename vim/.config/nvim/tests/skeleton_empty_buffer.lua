local function wait_for_scheduled()
  vim.wait(100, function()
    return false
  end, 10)
end

local populated_path = vim.fn.tempname() .. '.sh'
vim.api.nvim_create_autocmd('BufNewFile', {
  pattern = populated_path,
  once = true,
  callback = function()
    vim.api.nvim_set_current_line('created by another autocmd')
  end,
})

vim.cmd.edit(vim.fn.fnameescape(populated_path))
wait_for_scheduled()
assert(
  vim.api.nvim_get_current_line() == 'created by another autocmd',
  'a skeleton must not expand into a buffer populated by another autocmd'
)

vim.cmd('enew!')
local empty_path = vim.fn.tempname() .. '.sh'
vim.cmd.edit(vim.fn.fnameescape(empty_path))
wait_for_scheduled()
assert(
  vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '#!/usr/bin/env bash',
  'an empty new file should get a skeleton'
)

vim.cmd('qa!')
