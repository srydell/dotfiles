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
        'docker-dev-rocky8-dev-linux-arm64-latest',
        'bash',
        unpack(params.command),
      },
      components = {
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = require('srydell.compiler.helpers.cpp').get_errorformat(),
        },
        'default',
      },
    }
  end,
}
