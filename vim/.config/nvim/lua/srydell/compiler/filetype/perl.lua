local function get_compilers()
  return { { name = 'perl run', tasks = { 'perl' }, type = 'overseer' } }
end

return get_compilers()
