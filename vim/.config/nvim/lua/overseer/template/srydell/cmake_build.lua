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
        { 'on_output_quickfix', open_on_match = true },
        'default',
      },
    }
  end,
}
