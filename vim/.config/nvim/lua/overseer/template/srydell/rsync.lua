return {
  name = 'rsync',
  desc = 'rsync over files to bx machine and rerun last command',
  params = {
    project = {
      type = 'string',
      optional = false,
    },
  },
  builder = function(params)
    return {
      cmd = { 'rsync' },
      args = {
        '--exclude',
        "'.git'",
        '--exclude',
        'build',
        '-r',
        '--progress',
        '/Users/simryd/code/' .. params.project .. '/src',
        '/Users/simryd/code/' .. params.project .. '/scripts',
        'bx0052:/newhome/bx0004/simryd/code/' .. params.project,
      },
      components = {
        {
          'srydell.on_status_run_command',
          status = 'SUCCESS',
          command = 'VimuxRunCommand "!!"',
        },
        'default',
      },
    }
  end,
}
