return {
  name = 'perl',
  builder = function()
    local file = vim.fn.expand('%:p')
    return {
      cmd = { 'perl' },
      args = vim.list_extend({ file }, require('srydell.compiler.run_args').get(file)),
      components = {
        { 'srydell.on_start_save_all' },
        { 'on_output_parse', parser = require('srydell.compiler.helpers.perl_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        'default',
      },
    }
  end,
}
