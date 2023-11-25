return {
  name = 'rsync',
  desc = 'rsync over files to bx machine and rerun last command',
  builder = function()
    return {
      cmd = { 'rsync' },
      args = {
        '--exclude',
        "'.git'",
        '--exclude',
        'build',
        '-r',
        '--progress',
        '/Users/simryd/code/dsf/src',
        'bx0052:/newhome/bx0004/simryd/code/dsf',
      },
      components = {
        {
          'srydell.on_status_run_command',
          status = 'SUCCESS',
          command = function()
            vim.cmd('VimuxRunCommand "!!"')
          end,
        },
        'default',
      },
    }
  end,
}
