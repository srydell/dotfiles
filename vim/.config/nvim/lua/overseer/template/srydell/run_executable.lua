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
    local run_args = require('srydell.compiler.run_args').get(params.executable)
    return {
      cmd = { 'sh' },
      args = vim.list_extend({
        '-c',
        'if [ -x "$0" ]; then exec "$0" "$@"; else echo "Executable not found: $0"; exit 1; fi',
        params.executable,
      }, run_args),
      components = { { 'on_output_quickfix', open = true }, 'default' },
    }
  end,
}
