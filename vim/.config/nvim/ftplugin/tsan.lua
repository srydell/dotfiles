local function filter_tsan(opts)
  opts = opts or {}
  local cmd = {
    'python3',
    vim.fn.stdpath('config') .. '/tools/filter_tsan.py',
    '--filename',
    vim.fn.expand('%:p'),
  }

  if opts.remove_containing then
    table.insert(cmd, '--remove-containing')
    table.insert(cmd, opts.remove_containing)
  end

  if opts.keep_containing then
    table.insert(cmd, '--keep-containing')
    table.insert(cmd, opts.keep_containing)
  end

  if opts.as_json then
    table.insert(cmd, '--as-json')
  end

  return cmd
end

local function run_and_set(cmd)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.fn.systemlist(cmd))
end

local function no_filter()
  run_and_set(filter_tsan())
  vim.api.nvim_command('write')
end

local function remove_containing()
  local cmd = filter_tsan({ remove_containing = vim.fn.input('Remove containing: ') })
  run_and_set(cmd)
  vim.api.nvim_command('write')
end

local function keep_containing()
  local cmd = filter_tsan({ keep_containing = vim.fn.input('Keep containing: ') })
  run_and_set(cmd)
  vim.api.nvim_command('write')
end

local tsan = require('srydell.util.tsan')
local function load_tsan_into_quickfix()
  -- Run filter_tsan on the current buffer
  local output =
    vim.json.decode(vim.fn.system(filter_tsan({ as_json = true })), { luanil = { object = true, array = true } })

  tsan.load_tsan_into_quickfix_from_json(output)
end

local function remove_duplicates()
  -- Run filter_tsan on the current buffer
  local filtered_json = vim.fn.system(filter_tsan({ as_json = true }))
  local temp_path = '/tmp/tsan_temp_filtered.json'
  local temp = io.open(temp_path, 'w')
  if not temp then
    return
  end
  temp:write(filtered_json)
  temp:close()
  local no_duplicates = vim.fn.system({
    'python3',
    vim.fn.stdpath('config') .. '/tools/remove_tsan_duplicates.py',
    '--filename',
    temp_path,
  })
  local output = vim.json.decode(no_duplicates, { luanil = { object = true, array = true } })

  tsan.load_tsan_into_quickfix_from_json(output)
end

vim.keymap.set('n', '<leader>aa', no_filter, { buffer = true })
vim.keymap.set('n', '<leader>af', remove_containing, { buffer = true })
vim.keymap.set('n', '<leader>ac', keep_containing, { buffer = true })
vim.keymap.set('n', '<leader>ad', remove_duplicates, { buffer = true })
vim.keymap.set('n', '<leader>aq', load_tsan_into_quickfix, { buffer = true })
vim.keymap.set('n', ']s', tsan.goto_next_stack, { buffer = false })
vim.keymap.set('n', '[s', tsan.goto_previous_stack, { buffer = false })
vim.keymap.set('n', ']w', tsan.goto_next_tsan_warning, { buffer = false })
vim.keymap.set('n', '[w', tsan.goto_previous_tsan_warning, { buffer = false })
