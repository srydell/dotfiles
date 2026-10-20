local ts_cpp = require('srydell.treesitter.cpp')
local util_cpp = require('srydell.util.cpp')

-- Let 'gf' resolve project-relative #include paths (e.g. "tool/proj/tool.h")
-- by searching from the src/include/source/inc roots instead of just '.,,'.
vim.opt_local.path:prepend(util_cpp.get_include_roots())

-- On an #include line, prefer clangd's textDocument/definition (it resolves the
-- real file via compile_commands.json flags), falling back to normal 'gf'
-- (using 'path' above) if clangd isn't attached or finds nothing.
--
-- The fallback runs ':normal! gf' via pcall since Vim's E447 (file not found)
-- would otherwise surface as an uncaught Lua error from this callback instead
-- of the usual error message.
local function fallback_gf()
  local ok, err = pcall(vim.cmd, 'normal! gf')
  if not ok then
    -- Strip the "nvim_exec2()..." wrapper so only the real Vim error (e.g. "E447: ...") shows.
    vim.api.nvim_err_writeln(err:match('(E%d+:.*)') or err)
  end
end

vim.keymap.set('n', 'gf', function()
  local line = vim.api.nvim_get_current_line()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })

  if line:match('^%s*#%s*include') == nil or #clients == 0 then
    fallback_gf()
    return
  end

  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request('textDocument/definition', params, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      fallback_gf()
      return
    end

    local location = result[1] or result
    vim.lsp.util.show_document(location, client.offset_encoding, { focus = true })
  end, 0)
end, { buffer = true, desc = 'Go to file (clangd-aware)' })

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
