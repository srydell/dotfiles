return {
  desc = 'On start ensure some directory exists',
  params = {
    dir = {
      type = 'string',
      optional = false,
    },
  },
  constructor = function(params)
    return {
      on_pre_start = function(self, _task)
        vim.fn.mkdir(params.dir, 'p')
      end,
    }
  end,
}
