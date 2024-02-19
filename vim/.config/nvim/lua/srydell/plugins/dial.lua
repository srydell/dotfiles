return {
  'monaqa/dial.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local augend = require('dial.augend')
    require('dial.config').augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.new({
          pattern = '%Y/%m/%d',
          default_kind = 'day',
        }),
        augend.date.new({
          pattern = '%Y-%m-%d',
          default_kind = 'day',
        }),
        augend.date.new({
          pattern = '%m/%d',
          default_kind = 'day',
          only_valid = true,
        }),
        augend.date.new({
          pattern = '%H:%M',
          default_kind = 'day',
          only_valid = true,
        }),
        augend.constant.alias.ja_weekday_full,
        augend.constant.alias.bool,
        augend.semver.alias.semver,
      },
    })

    vim.keymap.set('n', '<C-a>', function()
      require('dial.map').manipulate('increment', 'normal')
    end)
    vim.keymap.set('n', '<C-x>', function()
      require('dial.map').manipulate('decrement', 'normal')
    end)
    vim.keymap.set('n', 'g<C-a>', function()
      require('dial.map').manipulate('increment', 'gnormal')
    end)
    vim.keymap.set('n', 'g<C-x>', function()
      require('dial.map').manipulate('decrement', 'gnormal')
    end)
    vim.keymap.set('v', '<C-a>', function()
      require('dial.map').manipulate('increment', 'visual')
    end)
    vim.keymap.set('v', '<C-x>', function()
      require('dial.map').manipulate('decrement', 'visual')
    end)
    vim.keymap.set('v', 'g<C-a>', function()
      require('dial.map').manipulate('increment', 'gvisual')
    end)
    vim.keymap.set('v', 'g<C-x>', function()
      require('dial.map').manipulate('decrement', 'gvisual')
    end)
  end,
}
