return {
  name = 'manim',
  builder = function()
    local python = require('srydell.compiler.helpers.python')
    return {
      cmd = { 'manim' },
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
