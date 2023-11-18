return {
  'stevearc/overseer.nvim',
  config = function()
    local overseer = require('overseer')
    overseer.setup()
  end,
}
