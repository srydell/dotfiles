return {
  'monaqa/dial.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  event = 'VeryLazy',
  config = function()
    local augend = require('dial.augend')
    local config = require('dial.config')
    local util = require('srydell.util')
    local default = {
      augend.integer.alias.decimal_int,
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
      augend.semver.alias.semver,
    }

    config.augends:register_group({
      default = util.merge({ augend.constant.alias.bool }, default),
    })

    config.augends:on_filetype({
      python = util.merge({ augend.constant.new({ elements = { 'True', 'False' } }) }, default),
      markdown = util.merge({ augend.misc.alias.markdown_header }, default),

      cpp = util.merge({
        augend.constant.new({
          elements = {
            'memory_order_relaxed',
            'memory_order_acquire',
            'memory_order_release',
          },
        }),
      }, default),
    })

    local manip = require('dial.map').manipulate
    vim.keymap.set('n', '<C-a>', function()
      manip('increment', 'normal')
    end)
    vim.keymap.set('n', '<C-x>', function()
      manip('decrement', 'normal')
    end)
    vim.keymap.set('n', 'g<C-a>', function()
      manip('increment', 'gnormal')
    end)
    vim.keymap.set('n', 'g<C-x>', function()
      manip('decrement', 'gnormal')
    end)
    vim.keymap.set('v', '<C-a>', function()
      manip('increment', 'visual')
    end)
    vim.keymap.set('v', '<C-x>', function()
      manip('decrement', 'visual')
    end)
    vim.keymap.set('v', 'g<C-a>', function()
      manip('increment', 'gvisual')
    end)
    vim.keymap.set('v', 'g<C-x>', function()
      manip('decrement', 'gvisual')
    end)
  end,
}
