return {
  name = 'scrapy',
  builder = function()
    local python = require('srydell.compiler.helpers.python')
    return {
      cmd = { 'scrapy' },
      args = {
        'runspider',
        '--loglevel',
        'WARNING',
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
