return {
  name = 'cmake configure',
  desc = 'Configure a CMake build directory',
  params = {
    build_dir = {
      type = 'string',
      optional = true,
      default = 'build',
    },
    build_type = {
      type = 'string',
      optional = true,
      default = 'RelWithDebInfo',
    },
  },
  builder = function(params)
    return {
      cmd = { 'cmake' },
      args = {
        '-S',
        '.',
        '-B',
        params.build_dir,
        '-DCMAKE_BUILD_TYPE=' .. params.build_type,
        '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      },
      components = {
        { 'srydell.on_start_save_all' },
        { 'on_output_quickfix', open_on_match = true },
        'default',
      },
    }
  end,
}
