return function()
  return { { name = 'perl run', executable = vim.fn.expand('%:p'), tasks = { task = 'perl' } } }
end
