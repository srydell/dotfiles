return {
  name = 'perl',
  builder = function()
    local perl = require('srydell.compiler.helpers.perl')
    local file = vim.fn.expand('%:p')
    return {
      cmd = { 'perl' },
      args = vim.list_extend({ file }, require('srydell.compiler.run_args').get(file)),
      components = {
        { 'srydell.on_start_save_all' },
        {
          'on_output_quickfix',
          open = true,
          errorformat = perl.get_errorformat(),
        },
        'default',
      },
    }
  end,
}
