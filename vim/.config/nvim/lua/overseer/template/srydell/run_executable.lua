return {
  name = 'run executable',
  desc = 'Run an executable',
  params = {
    executable = {
      type = 'string',
      optional = false,
    },
  },
  builder = function(params)
    return {
      cmd = { 'sh' },
      args = {
        '-c',
        'if [ -x "$1" ]; then exec "$1"; else echo "Executable not found: $1"; exit 1; fi',
        'sh',
        params.executable,
      },
      components = { { 'on_output_quickfix', open = true }, 'default' },
    }
  end,
}
