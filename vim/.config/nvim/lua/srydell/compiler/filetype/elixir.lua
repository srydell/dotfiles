return function()
  local icons = require('srydell.constants').icons
  -- Elixir script?
  if vim.fn.expand('%:e') == 'exs' then
    return {
      { name = 'Elixir ' .. icons.building, executable = vim.fn.expand('%:p'), tasks = { task = 'elixir script' } },
    }
  end
  return {}
end
