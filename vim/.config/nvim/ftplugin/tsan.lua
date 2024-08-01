local function filter_tsan(filter)
  local cmd = {
    'python3',
    vim.fn.stdpath('config') .. '/tools/filter_tsan.py',
    '--filename',
    vim.fn.expand('%:p'),
  }

  if filter then
    table.insert(cmd, '--remove-containing')
    table.insert(cmd, filter)
  end

  local filtered_content = vim.fn.systemlist(cmd)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, filtered_content)
end

local function remove_containing()
  filter_tsan(vim.fn.input('Remove containing: '))
end

vim.keymap.set('n', '<leader>aa', filter_tsan)
vim.keymap.set('n', '<leader>af', remove_containing)
