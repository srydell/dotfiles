return {
  desc = 'Before starting task, run a shell command synchronously',
  -- Define parameters that can be passed in to the component
  params = {
    cmd = {
      type = 'string',
      optional = false,
    },
  },
  constructor = function(params)
    return {
      on_pre_start = function(self, _task)
        -- Make sure it's synchronous
        -- NOTE: vim.fn.system calls jobstart in the background
        vim.cmd('!' .. params.cmd)
      end,
    }
  end,
}
