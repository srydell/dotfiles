return {
  name = 'docker run',
  desc = 'Run a command within a running docker container',
  builder = function()
    local cpp = require('srydell.compiler.helpers.cpp')
    local cwd = vim.fn.getcwd()
    local script = vim.fn.stdpath('config') .. '/tools/build_waf.sh'
    return {
      cmd = { 'docker' },
      args = {
        'exec',
        '--workdir',
        cwd,
        '-t',
        'docker-dev-rocky8-dev-linux-arm64-latest',
        'bash',
        script,
      },
      components = {
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = cpp.get_errorformat(),
        },
        'default',
      },
    }
  end,
}
