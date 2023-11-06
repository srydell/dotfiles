return
{
  'L3MON4D3/LuaSnip',
  -- follow latest release.
  version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  -- install jsregexp (optional!).
  build = 'make install_jsregexp',
  config = function ()
    -- NOTE: Keymaps are defined in cmp-nvim since interactions in popup is weird
    local ls = require('luasnip')
    require('luasnip.loaders.from_lua').load({paths = '~/.config/nvim/snips/'})

    vim.keymap.set('n', '<leader><leader>l', function()
      require('luasnip.loaders.from_lua').load({paths = '~/.config/nvim/snips/'})
    end)

    -- vim.keymap.set({ 'i', 's' }, '<C-E>', function()
    --   close_cmp()
    --   if ls.expand_or_jumpable() then
    --     ls.expand_or_jump()
    --   end
    -- end)

    -- vim.keymap.set({ 'i', 's' }, '<C-H>', function()
    --   cmp.close()
    --   if ls.jumpable(-1) then
    --     ls.jump(-1)
    --   end
    -- end)

    -- vim.keymap.set({ 'i', 's' }, '<C-K>', function()
    --   close_cmp()
    --   if ls.choice_active() then
    --     ls.change_choice(1)
    --   end
    -- end)

    -- vim.keymap.set({ 'i', 's' }, '<C-J>', function()
    --   close_cmp()
    --   if ls.choice_active() then
    --     ls.change_choice(-1)
    --   end
    -- end)

    ls.config.set_config({
        -- Remember to keep around the last snippet
        -- and be able to jump into it
        -- history = true,

        -- Update dynamic snippets as you type
        updateevents = 'TextChanged,TextChangedI',

        -- Enable autotriggered snippets
        enable_autosnippets = true,

        -- Trigger visual selection
        store_selection_keys = '<C-E>',
      })
  end
}
