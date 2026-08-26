return {
  name = 'lua',
  builder = function()
    local path = './' .. vim.fn.expand('%')
    local run_args = require('srydell.compiler.run_args').get(vim.fn.expand('%:p'))
    return {
      cmd = { 'lua' },
      args = vim.list_extend({ path }, run_args),
      components = {
        { 'srydell.on_start_save_all' },
        { 'on_output_parse', parser = require('srydell.compiler.helpers.lua_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        'default',
      },
    }
  end,
}
