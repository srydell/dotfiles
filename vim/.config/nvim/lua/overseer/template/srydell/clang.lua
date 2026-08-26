return {
  name = 'clang',
  desc = 'Compile and run or debug C++ using clang++',
  params = {
    will_do = {
      type = 'enum',
      optional = false,
      choices = { 'RUN', 'DEBUG' },
    },
    with_warnings = {
      type = 'boolean',
      default = true,
    },
  },
  builder = function(params)
    local cpp = require('srydell.compiler.helpers.cpp')
    local full_path = vim.fn.expand('%:p')
    local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
    return {
      cmd = { 'clang++' },
      args = cpp.get_args('clang', full_path, executable, params.with_warnings),
      components = {
        { 'srydell.on_start_save_all' },
        { 'srydell.on_start_ensure_exists', dir = 'build/bin' },
        -- Pure-Lua diagnostic parsing (see cpp_parser.lua) instead of vim
        -- errorformat; only surfaces results once, at task completion.
        { 'on_output_parse', parser = require('srydell.compiler.helpers.cpp_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        { 'srydell.on_end_run_or_debug', executable = executable, will_do = params.will_do },
        {
          'srydell.on_end_create_compile_flags_txt',
          flags = table.concat(cpp.get_flags('clang', params.with_warnings), '\n'),
        },
        'default',
      },
    }
  end,
}
