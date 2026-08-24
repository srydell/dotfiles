return {
  name = 'python',
  builder = function()
    local python = require('srydell.compiler.helpers.python')
    local file = vim.fn.expand('%:p')
    return {
      cmd = { 'python3' },
      args = vim.list_extend({ file }, require('srydell.compiler.run_args').get(file)),
      components = {
        { 'srydell.on_start_save_all' },
        {
          'on_output_quickfix',
          open = true,
          errorformat = python.get_errorformat(),
        },
        'default',
      },
    }
  end,
}
