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
      cmd = { 'perf' },
      args = {
        'stat',
        '--event',
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
