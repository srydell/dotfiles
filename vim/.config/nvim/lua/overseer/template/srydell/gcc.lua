return {
  name = 'g++',
  desc = 'Compile and run or debug C++ using g++',
  builder = function()
    local cpp = require('srydell.compiler.cpp')
    local full_path = vim.fn.expand('%:p')
    local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
    return {
      cmd = { 'g++' },
      args = cpp.get_args('gcc', full_path, executable),
      components = {
        { 'srydell.on_start_ensure_exists', dir = 'build/bin' },
        { 'srydell.on_end_run_or_debug', executable = executable, will_do = 'RUN' },
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = cpp.get_errorformat(),
        },
        'default',
      },
    }
  end,
  condition = {
    filetype = 'cpp',
  },
}
