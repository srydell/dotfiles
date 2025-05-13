return {
  name = 'tolc_prototype',
  desc = 'Compile a python thingie with tolc',
  builder = function()
    local cpp = require('srydell.compiler.helpers.cpp')
    local module = vim.fn.expand('%:p:t:r')
    return {
      cmd = { './build.sh' },
      args = { module },
      components = {
        { 'srydell.on_start_ensure_exists', dir = 'build' },
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = cpp.get_errorformat(),
        },
        'default',
      },
    }
  end,
}
