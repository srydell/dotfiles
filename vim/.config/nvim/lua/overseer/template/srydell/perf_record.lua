return {
  name = 'perf record',
  desc = 'Run perf record with DWARF call graphs',
  params = {
    executable = {
      type = 'string',
      optional = false,
    },
  },
  builder = function(params)
    return {
      cmd = { 'perf' },
      args = { 'record', '--call-graph', 'dwarf', params.executable },
      components = { { 'on_output_quickfix', open = true }, 'default' },
    }
  end,
}
