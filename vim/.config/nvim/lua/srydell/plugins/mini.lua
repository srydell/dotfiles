return {
  'echasnovski/mini.nvim',
  -- Textobjects/diff-signs/operators aren't needed before the first frame;
  -- defer a few ms without changing behavior.
  event = 'VeryLazy',
  config = function()
    require('mini.ai').setup()
    require('mini.diff').setup()
    require('mini.operators').setup()
  end,
}
