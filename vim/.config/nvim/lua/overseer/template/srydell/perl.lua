return {
  name = 'perl',
  builder = function()
    local perl = require('srydell.compiler.helpers.perl')
    return {
      cmd = { 'perl' },
      args = {
        vim.fn.expand('%:p'),
      },
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
