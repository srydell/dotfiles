local function get_compilers()
  return {
    { name = 'python run', tasks = { task = 'python' } },
  }
end

return get_compilers()
