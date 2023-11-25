return {
  name = 'python',
  builder = function()
    local python = require('srydell.compiler.python')
    return {
      cmd = { 'python3' },
      args = {
        vim.fn.expand('%:p'),
      },
      components = {
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
