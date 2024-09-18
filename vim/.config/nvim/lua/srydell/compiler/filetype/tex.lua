local function get_compilers()
  return { { name = 'tex', tasks = { 'latexmk' } } }
end

return get_compilers()
