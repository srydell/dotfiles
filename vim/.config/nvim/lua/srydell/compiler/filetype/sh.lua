local function get_compilers()
  return {
    { name = 'sh run', tasks = { task = 'sh' } },
  }
end

return get_compilers()
