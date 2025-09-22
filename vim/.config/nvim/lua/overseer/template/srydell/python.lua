return {
  name = 'python',
  builder = function()
    local python = require('srydell.compiler.helpers.python')
    return {
      cmd = { 'python3' },
      args = {
        vim.fn.expand('%:p'),
      },
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
