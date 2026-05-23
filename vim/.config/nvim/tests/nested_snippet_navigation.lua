local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local navigation = require('srydell.snips.navigation')

local function wait_for_scheduled()
  vim.wait(100, function()
    return false
  end, 10)
end

vim.cmd('enew')
vim.bo.filetype = 'snippet_navigation_test'
ls.add_snippets('snippet_navigation_test', {
  s('outer', {
    t({ 'outer {', '  ' }),
    i(1, 'body'),
    t({ '', '}' }),
    i(0),
  }),
  s('inner', {
    t('inner_expanded'),
  }),
})

vim.api.nvim_set_current_line('outer')
vim.api.nvim_win_set_cursor(0, { 1, 5 })
vim.cmd('startinsert!')
navigation.forward()
wait_for_scheduled()
assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == 'outer {', 'outer snippet should expand')
assert(ls.jumpable(1), 'outer snippet should still be jumpable while editing first node')

vim.api.nvim_win_set_cursor(0, { 2, 6 })
vim.api.nvim_set_current_line('  inner')
vim.api.nvim_win_set_cursor(0, { 2, 7 })
assert(ls.expandable(), 'inner trigger should be expandable inside active outer snippet')
assert(ls.jumpable(1), 'outer snippet should still be jumpable while inner trigger is expandable')

navigation.forward()
wait_for_scheduled()
assert(vim.api.nvim_get_current_line() == '  inner_expanded', 'inner snippet should expand before jumping outer snippet')

vim.cmd('qa!')
