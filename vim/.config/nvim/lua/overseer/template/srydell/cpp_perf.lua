local function get_perf_command(mode, executable)
  if mode == 'RECORD' then
    return {
      name = 'perf record',
      cmd = { 'perf' },
      args = { 'record', '--call-graph', 'dwarf', executable },
    }
  end

  return {
    name = 'perf stat',
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
      executable,
    },
  }
end

return {
  name = 'cpp perf',
  desc = 'Compile C++ with profiling-friendly flags and run perf',
  params = {
    compiler = {
      type = 'enum',
      optional = false,
      choices = { 'clang', 'gcc' },
    },
    mode = {
      type = 'enum',
      optional = false,
      choices = { 'STAT', 'RECORD' },
    },
  },
  builder = function(params)
    local cpp = require('srydell.compiler.helpers.cpp')
    local full_path = vim.fn.expand('%:p')
    local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
    local compiler_cmd = params.compiler == 'clang' and 'clang++' or 'g++'
    local perf = get_perf_command(params.mode, executable)

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
        { 'srydell.on_end_run_command', name = perf.name, cmd = perf.cmd, args = perf.args },
        'default',
      },
    }
  end,
}
