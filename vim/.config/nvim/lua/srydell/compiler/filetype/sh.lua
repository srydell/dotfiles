local function get_compilers()
  return {
    { name = 'sh run', tasks = { 'sh' }, type = 'overseer' },
  }
end

return get_compilers()
