local ts_cpp = require('srydell.treesitter.cpp')

vim.keymap.set('n', '<leader>gr', ts_cpp.find_enum_from_type)

-- 'r' is for refactor
vim.keymap.set('n', '<leader>raa', ts_cpp.make_atomic)
vim.keymap.set('n', '<leader>ral', ts_cpp.make_atomic_load)
vim.keymap.set('n', '<leader>ras', ts_cpp.make_atomic_store)
vim.keymap.set('n', '<leader>ree', ts_cpp.make_enum_switch)
vim.keymap.set('n', '<leader>rep', ts_cpp.make_enum_print)
vim.keymap.set('n', '<leader>res', ts_cpp.make_enum_stringify)
vim.keymap.set('n', '<leader>reb', ts_cpp.make_enum_binary)
