return {
  name = 'cpp perf compile',
  desc = 'Compile C++ with profiling-friendly flags',
  params = {
    compiler = {
      type = 'enum',
      optional = false,
      choices = { 'clang', 'gcc' },
    },
  },
  builder = function(params)
    local cpp = require('srydell.compiler.helpers.cpp')
    local full_path = vim.fn.expand('%:p')
    local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
    local compiler_cmd = params.compiler == 'clang' and 'clang++' or 'g++'

    return {
      cmd = { compiler_cmd },
      args = cpp.get_perf_args(params.compiler, full_path, executable),
      components = {
        { 'srydell.on_start_save_all' },
        { 'srydell.on_start_ensure_exists', dir = 'build/bin' },
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = cpp.get_errorformat(),
        },
        {
          'srydell.on_end_create_compile_flags_txt',
          flags = table.concat(cpp.get_perf_flags('clang'), '\n'),
        },
        'default',
      },
    }
  end,
}
