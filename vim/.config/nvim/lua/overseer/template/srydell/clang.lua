return {
  name = 'clang',
  desc = 'Compile and run or debug C++ using clang++',
  params = {
    will_do = {
      type = 'enum',
      optional = false,
      choices = { 'RUN', 'DEBUG' },
    },
  },
  builder = function(params)
    local cpp = require('srydell.compiler.helpers.cpp')
    local full_path = vim.fn.expand('%:p')
    local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
    return {
      cmd = { 'clang++' },
      args = cpp.get_args('clang', full_path, executable),
      components = {
        { 'srydell.on_start_save_all' },
        { 'srydell.on_start_ensure_exists', dir = 'build/bin' },
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = cpp.get_errorformat(),
        },
        { 'srydell.on_end_run_or_debug', executable = executable, will_do = params.will_do },
        { 'srydell.on_end_create_compile_flags_txt', flags = table.concat(cpp.get_flags('clang'), '\n') },
        'default',
      },
    }
  end,
}
