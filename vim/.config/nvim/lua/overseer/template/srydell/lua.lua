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
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = [[%s: %f:%l:%m]],
        },
        'default',
      },
    }
  end,
}
