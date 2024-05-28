return {
  name = 'rsync',
  desc = 'rsync over files to remote or bx machine and rerun last command',
  params = {
    project = {
      type = 'string',
      optional = false,
    },
  },
  builder = function(params)
    local remote = os.getenv('REMOTE_MACHINE') or 'bx0052'

    return {
      cmd = { 'rsync' },
      args = {
        '--exclude',
        params.project .. '/.git',
        '--exclude',
        params.project .. '/build',
        '--exclude',
        params.project .. '/data',
        '--exclude',
        params.project .. '/temp',
        '-r',
        '--progress',
        '/Users/simryd/code/' .. params.project,
        remote .. ':/home/simryd/code/',
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
