local function breakup()
  local cmd = {
    'python3',
    vim.fn.stdpath('config') .. '/tools/breakup_scenario_log.py',
    '--input',
    vim.fn.expand('%:p'),
  }

  return cmd
end

local function count_warnings(file)
  local content = io.open(file)
  if content == nil then
    return 0
  end

  local warnings = 0
  for line in content:lines() do
    if line:match('WARNING: ThreadSanitizer:') ~= nil then
      warnings = warnings + 1
    end
  end
  return warnings
end

local function split_into_parts()
  local broken_up_files = vim.json.decode(vim.fn.system(breakup()), { luanil = { object = true, array = true } })

  local to_be_shown = {}
  for _, file in ipairs(broken_up_files['files']) do
    table.insert(to_be_shown, file .. ', ' .. count_warnings(file) .. ' warnings')
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local opts = {}
  local util = require('srydell.util')
  pickers
    .new(opts, {
      prompt_title = 'Processor files',
      finder = finders.new_table({
        results = to_be_shown,
      }),
      sorter = conf.generic_sorter(opts),
      -- previewer = conf.file_previewer(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.print(selection)
          local file = util.split(selection[1], ',')[1]
          vim.print(file)
          vim.cmd('edit ' .. file)
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set('n', '<leader>as', split_into_parts)
