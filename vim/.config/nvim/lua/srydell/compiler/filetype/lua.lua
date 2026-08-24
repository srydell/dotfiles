return function()
  return {
    { name = 'lua run', executable = vim.fn.expand('%:p'), tasks = { task = 'lua' } },
  }
end
