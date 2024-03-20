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

    local unlinkgrp = vim.api.nvim_create_augroup('UnlinkSnippetOnModeChange', { clear = true })

    vim.api.nvim_create_autocmd('ModeChanged', {
      group = unlinkgrp,
      pattern = { 's:n', 'i:*' },
      desc = 'Forget the current snippet when leaving the insert mode',
      callback = function(evt)
        if ls.session and ls.session.current_nodes[evt.buf] and not ls.session.jump_active then
          ls.unlink_current()
        end
      end,
    })

    vim.api.nvim_create_autocmd('ModeChanged', {
      group = vim.api.nvim_create_augroup('UnlinkLuaSnipSnippetOnModeChange', {
        clear = true,
      }),
      pattern = { 's:n', 'i:*' },
      desc = 'Forget the current snippet when leaving the insert mode',
      callback = function(evt)
        -- If we have n active nodes, n - 1 will still remain after a `unlink_current()` call.
        -- We unlink all of them by wrapping the calls in a loop.
        while true do
          if ls.session and ls.session.current_nodes[evt.buf] and not ls.session.jump_active then
            ls.unlink_current()
          else
            break
          end
        end
      end,
    })
  end,
}
