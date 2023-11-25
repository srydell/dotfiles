return {
  desc = 'On task matching status, run a command function',
  params = {
    status = {
      type = 'string',
      optional = true,
      default = 'SUCCESS',
    },
    command = {
      type = 'string',
      optional = true,
      default = 'VimuxRunCommand "!!"',
    },
  },
  constructor = function(params)
    return {
      on_complete = function(self, _task, status, _result)
        -- Called when the task has reached a completed state.
        if status == params.status then
          vim.cmd(params.command)
        end
      end,
    }
  end,
}
