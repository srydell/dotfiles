local ls = require('luasnip')
local function assert_cursor_col(expected, message)
  local col = vim.api.nvim_win_get_cursor(0)[2]
  assert(col == expected, string.format('%s: expected col %d, got %d', message, expected, col))
end

local function wait_for_scheduled()
  vim.wait(100, function()
    return false
  end, 10)
end

local function flush_keys()
  vim.wait(100, function()
    return true
  end, 10)
end

local function assert_lsp_snippet_jumpable(message)
  assert(ls.in_snippet(), message .. ': LuaSnip should still own the active snippet')
  assert(ls.jumpable(1), message .. ': snippet should be jumpable')
end

vim.cmd('enew')
vim.bo.filetype = 'cpp'
vim.api.nvim_feedkeys('i', 'x', false)
flush_keys()
require('blink.cmp.config').snippets.expand('lsp_call(${1:first}, ${2:second})$0')
vim.cmd('normal! v')
wait_for_scheduled()
assert(vim.api.nvim_get_current_line() == 'lsp_call(first, second)', 'LSP snippet should expand')
assert_cursor_col(8, 'LSP snippet should land on first node')
assert_lsp_snippet_jumpable('after LSP expansion')

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
wait_for_scheduled()
assert(not ls.in_snippet(), 'leaving the snippet should clear LuaSnip state')

vim.cmd('qa!')
