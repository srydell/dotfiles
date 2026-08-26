return {
  name = 'scrapy',
  builder = function()
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
        { 'on_output_parse', parser = require('srydell.compiler.helpers.python_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        'default',
      },
    }
  end,
}
