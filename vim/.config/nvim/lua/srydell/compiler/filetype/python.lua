local function get_compilers()
  return {
    { name = 'python run', tasks = { 'python' }, type = 'overseer' },
  }
end

return get_compilers()
