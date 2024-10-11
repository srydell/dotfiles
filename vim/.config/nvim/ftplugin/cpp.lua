local ts_cpp = require('srydell.treesitter.cpp')

-- 'r' is for refactor
vim.keymap.set('n', '<leader>raa', ts_cpp.make_atomic)
vim.keymap.set('n', '<leader>ral', ts_cpp.make_atomic_load)
vim.keymap.set('n', '<leader>ras', ts_cpp.make_atomic_store)
vim.keymap.set('n', '<leader>ree', ts_cpp.make_enum_switch)
vim.keymap.set('n', '<leader>rep', ts_cpp.make_enum_print)
vim.keymap.set('n', '<leader>res', ts_cpp.make_enum_stringify)
vim.keymap.set('n', '<leader>reb', ts_cpp.make_enum_binary)
vim.keymap.set('n', '<leader>rcc', ts_cpp.make_class_constructor)
vim.keymap.set('n', '<leader>rcd', ts_cpp.make_class_destructor)
vim.keymap.set('n', '<leader>rcnm', ts_cpp.make_class_no_move)
vim.keymap.set('n', '<leader>rcnc', ts_cpp.make_class_no_copy)
