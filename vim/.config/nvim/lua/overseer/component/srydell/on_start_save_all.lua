return {
  desc = 'Before starting task, save all files',
  constructor = function()
    return {
      on_pre_start = function(self, _task)
        vim.cmd('wall')
      end,
    }
  end,
}
