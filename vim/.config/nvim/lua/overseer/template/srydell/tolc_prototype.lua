return {
  name = 'tolc_prototype',
  desc = 'Compile a python thingie with tolc',
  builder = function()
    local module = vim.fn.expand('%:p:t:r')
    return {
      cmd = { './build.sh' },
      args = { module },
      components = {
        { 'srydell.on_start_save_all' },
        { 'srydell.on_start_ensure_exists', dir = 'build' },
        { 'on_output_parse', parser = require('srydell.compiler.helpers.cpp_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        'default',
      },
    }
  end,
}
