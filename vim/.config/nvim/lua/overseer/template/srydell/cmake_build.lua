return {
  name = 'cmake build',
  desc = 'Build a CMake target',
  params = {
    build_dir = {
      type = 'string',
      optional = true,
      default = 'build',
    },
    target = {
      type = 'string',
      optional = false,
    },
  },
  builder = function(params)
    return {
      cmd = { 'cmake' },
      args = {
        '--build',
        params.build_dir,
        '--target',
        params.target,
        '--parallel',
      },
      components = {
        -- The underlying build (ninja/make invoking clang/gcc) emits
        -- clang/gcc-shaped diagnostics, not CMake's own configure-time
        -- messages -- reuse the C++ parser here rather than cmake_parser.lua
        -- (which only understands "CMake Error/Warning at ..." lines).
        { 'on_output_parse', parser = require('srydell.compiler.helpers.cpp_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        { 'open_output', on_start = 'never', on_complete = 'success', direction = 'horizontal', focus = false },
        'default',
      },
    }
  end,
}
