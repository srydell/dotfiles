local ts_cpp = require('srydell.treesitter.cpp')

-- 'r' is for refactor
vim.keymap.set('n', '<leader>raa', ts_cpp.make_atomic, { buffer = true })
vim.keymap.set('n', '<leader>ral', ts_cpp.make_atomic_load, { buffer = true })
vim.keymap.set('n', '<leader>ras', ts_cpp.make_atomic_store, { buffer = true })
vim.keymap.set('n', '<leader>ree', ts_cpp.make_enum_switch, { buffer = true })
vim.keymap.set('n', '<leader>rep', ts_cpp.make_enum_print, { buffer = true })
vim.keymap.set('n', '<leader>res', ts_cpp.make_enum_stringify, { buffer = true })
vim.keymap.set('n', '<leader>reb', ts_cpp.make_enum_binary, { buffer = true })
vim.keymap.set('n', '<leader>rcc', ts_cpp.make_class_constructor, { buffer = true })
vim.keymap.set('n', '<leader>rcd', ts_cpp.make_class_destructor, { buffer = true })
vim.keymap.set('n', '<leader>rcnm', ts_cpp.make_class_no_move, { buffer = true })
vim.keymap.set('n', '<leader>rcnc', ts_cpp.make_class_no_copy, { buffer = true })

-- Show the memory layout (offsets/padding/size/align) of the struct/class
-- under the cursor. See lua/srydell/util/struct_layout.lua.
vim.api.nvim_buf_create_user_command(0, 'StructLayout', function()
  require('srydell.util.struct_layout').show()
end, {})
vim.keymap.set('n', '<leader>rsl', '<cmd>StructLayout<CR>', { buffer = true })
