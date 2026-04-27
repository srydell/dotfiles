return {
  name = 'perf stat',
  desc = 'Run perf stat with explicit events',
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
        'if [ -x "$2" ]; then exec perf stat --event "$1" "$2"; else echo "Executable not found: $2"; exit 1; fi',
        'sh',
        table.concat({
          'task-clock',
          'cycles',
          'instructions',
          'branches',
          'branch-misses',
          'cache-references',
          'cache-misses',
          'context-switches',
          'cpu-migrations',
          'page-faults',
        }, ','),
        params.executable,
      },
      components = { { 'on_output_quickfix', open = true }, 'default' },
    }
  end,
}
