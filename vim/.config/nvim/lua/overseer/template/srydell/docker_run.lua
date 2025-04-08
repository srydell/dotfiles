return {
  name = 'docker run',
  desc = 'Run a command within a running docker container. If compiler option set, append it to command.',
  params = {
    command = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
  },
  builder = function(params)
    local command = params.command
    local option = require('srydell.compiler.options').get_compiler_option()
    if option ~= '' then
      table.insert(command, option)
    end
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
