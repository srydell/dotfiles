local function get_compilers()
  return {
    { name = 'lua run', tasks = { 'lua' }, type = 'overseer' },
  }
end

return get_compilers()
