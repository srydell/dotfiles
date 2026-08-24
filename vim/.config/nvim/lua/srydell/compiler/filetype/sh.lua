return function()
  return {
    {
      name = 'sh run',
      executable = vim.fn.expand('%:p'),
      tasks = { task = 'sh' },
    },
  }
end
