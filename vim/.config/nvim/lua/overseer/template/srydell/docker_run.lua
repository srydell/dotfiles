return {
  name = 'docker run',
  desc = 'Run a command within a running docker container.',
  params = {
    command = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
  },
  builder = function(params)
    return {
      cmd = { 'docker' },
      args = {
        'exec',
        '--workdir',
        vim.fn.getcwd(),
        '-t',
        'docker-dev-rocky8-dev-linux-arm64-arm64',
        'bash',
        unpack(params.command),
      },
      components = {
        { 'srydell.on_start_save_all' },
        -- Pure-Lua diagnostic parsing (see cpp_parser.lua) instead of vim
        -- errorformat; results are only surfaced once, from the fully
        -- buffered output at task completion. This also sidesteps the false
        -- positives `tail = true` errorformat parsing used to hit here: this
        -- task runs under a pty (`docker exec -t`), and waf/ninja's live
        -- progress bar can leave stray partial lines mid-stream that used to
        -- spuriously satisfy the errorformat and open the quickfix window
        -- even for a fully successful build.
        { 'on_output_parse', parser = require('srydell.compiler.helpers.cpp_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        'default',
      },
    }
  end,
}
