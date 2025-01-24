local function get_compilers()
  local icons = require('srydell.constants').icons
  -- Elixir script?
  if vim.fn.expand('%:e') == 'exs' then
    return { { name = 'Elixir ' .. icons.building, tasks = { 'elixir script' } } }
  end
end

return get_compilers()
