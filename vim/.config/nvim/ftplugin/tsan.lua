local sanitizer_buffer = require('srydell.util.sanitizer_buffer')
local api = sanitizer_buffer.setup('filter_tsan.py', 'TSAN output')

-- TSAN-only: dedupe near-identical warnings by hashing their read/write
-- stacks (see tools/remove_tsan_duplicates.py).
local function remove_duplicates()
  local filtered_json = vim.fn.system(api.build_cmd({ as_json = true }))
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

  require('srydell.util.sanitizer').load_into_quickfix_from_json(output, 'TSAN output')
end

vim.keymap.set('n', '<leader>ad', remove_duplicates, { buffer = true })
