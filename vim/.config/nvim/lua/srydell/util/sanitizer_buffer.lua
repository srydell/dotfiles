-- Wires up the standard keymaps shared by every sanitizer-log filetype
-- (tsan/asan/lsan/ubsan). Each ftplugin/<sanitizer>.lua calls M.setup() with
-- the tools/filter_*.py script and quickfix title for that sanitizer.
local sanitizer = require('srydell.util.sanitizer')

local M = {}

-- `tool_script` is a python tool under nvim's tools/ dir, e.g. 'filter_asan.py'.
-- `title` names the quickfix list, e.g. 'ASAN output'.
--
-- Returns { build_cmd, run_and_set } so filetype-specific ftplugins can add
-- their own extra keymaps on top (see ftplugin/tsan.lua's dedup command).
M.setup = function(tool_script, title)
  local function build_cmd(opts)
    opts = opts or {}
    local cmd = {
      'python3',
      vim.fn.stdpath('config') .. '/tools/' .. tool_script,
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
    run_and_set(build_cmd())
    vim.api.nvim_command('write')
  end

  local function remove_containing()
    run_and_set(build_cmd({ remove_containing = vim.fn.input('Remove containing: ') }))
    vim.api.nvim_command('write')
  end

  local function keep_containing()
    run_and_set(build_cmd({ keep_containing = vim.fn.input('Keep containing: ') }))
    vim.api.nvim_command('write')
  end

  local function load_into_quickfix()
    local output =
      vim.json.decode(vim.fn.system(build_cmd({ as_json = true })), { luanil = { object = true, array = true } })
    sanitizer.load_into_quickfix_from_json(output, title)
  end

  vim.keymap.set('n', '<leader>aa', no_filter, { buffer = true })
  vim.keymap.set('n', '<leader>af', remove_containing, { buffer = true })
  vim.keymap.set('n', '<leader>ac', keep_containing, { buffer = true })
  vim.keymap.set('n', '<leader>aq', load_into_quickfix, { buffer = true })
  vim.keymap.set('n', ']s', sanitizer.goto_next_stack, { buffer = false })
  vim.keymap.set('n', '[s', sanitizer.goto_previous_stack, { buffer = false })
  vim.keymap.set('n', ']w', sanitizer.goto_next_warning, { buffer = false })
  vim.keymap.set('n', '[w', sanitizer.goto_previous_warning, { buffer = false })

  return { build_cmd = build_cmd, run_and_set = run_and_set }
end

return M
