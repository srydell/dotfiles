return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup()
    require('mini.diff').setup()
    require('mini.operators').setup()
  end,
}
