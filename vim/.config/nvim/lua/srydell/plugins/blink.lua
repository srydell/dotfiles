return {
  'saghen/blink.cmp',

  -- use a release tag to download pre-built binaries
  version = '1.*',
  dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  config = function()
    local ls = require('luasnip')
    local blink = require('blink.cmp')
    blink.setup({
      keymap = {
        preset = 'default',
        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },

        ['<S-k>'] = { 'scroll_documentation_up', 'fallback' },
        ['<S-j>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
      },

      snippets = { preset = 'luasnip' },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        list = {
          selection = {
            preselect = function(ctx)
              return not require('blink.cmp').snippet_active({ direction = 1 })
            end,
            auto_insert = true,
          },
        },
        documentation = { auto_show = false },
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    })
  end,
  opts_extend = { 'sources.default' },
}
