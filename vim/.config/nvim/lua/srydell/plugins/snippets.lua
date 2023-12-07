return {
  'L3MON4D3/LuaSnip',
  -- follow latest release.
  version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  -- install jsregexp (optional!).
  build = 'make install_jsregexp',
  config = function()
    -- NOTE: Keymaps are defined in cmp-nvim since interactions in popup is weird
    local ls = require('luasnip')
    require('luasnip.loaders.from_lua').load({ paths = '~/.config/nvim/snips/' })

    vim.keymap.set('n', '<leader><leader>l', function()
      require('luasnip.loaders.from_lua').load({ paths = '~/.config/nvim/snips/' })
    end)

    ls.config.set_config({
      -- Update dynamic snippets as you type
      updateevents = { 'TextChanged', 'TextChangedI' },

      -- Enable autotriggered snippets
      enable_autosnippets = true,

      -- Trigger visual selection
      store_selection_keys = '<C-E>',
    })
  end,
}
