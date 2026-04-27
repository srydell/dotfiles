return function()
  local icons = require('srydell.constants').icons
  -- Elixir script?
  if vim.fn.expand('%:e') == 'exs' then
    return { { name = 'Elixir ' .. icons.building, tasks = { task = 'elixir script' } } }
  end
  return {}
end
