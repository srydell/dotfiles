return {
  name = 'git push',
  desc = 'Run a git push command',
  builder = function()
    local branch = io.popen('git branch --show-current'):read()
    return {
      cmd = { 'git' },
      args = { 'push', 'origin', 'HEAD:' .. branch },
      components = {
        { 'srydell.on_start_run_sh', cmd = 'git add -u && git commit -m "Commit to be squashed"' },
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
