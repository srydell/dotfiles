local function get_compilers()
  return {
    { name = 'lua run', tasks = { task = 'lua' } },
  }
end

return get_compilers()
