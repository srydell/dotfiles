local function my_test()
  vim.print('Hello from inside the test')
  return true
end

local function get_compilers()
  return {
    {
      name = 'func test',
      tasks = { { 'lua function', f = my_test }, { 'shell', cmd = 'echo hello from later' } },
    },
    { name = 'lua run', tasks = { 'lua' } },
  }
end

return get_compilers()
