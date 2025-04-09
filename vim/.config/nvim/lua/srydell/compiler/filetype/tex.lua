local function get_compilers()
  return { { name = 'tex', tasks = { task = 'latexmk' } } }
end

return get_compilers()
