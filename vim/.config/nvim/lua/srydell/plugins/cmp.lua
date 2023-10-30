return
{
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lua',
    'petertriho/cmp-git',
    'saadparwaiz1/cmp_luasnip',
    'L3MON4D3/LuaSnip',
  },

  config = function()
    local cmp = require('cmp')
    local ls = require('luasnip')

    cmp.setup({
        -- Disable for not modifiable pages (for manpager)
        -- See https://github.com/hrsh7th/nvim-cmp/issues/1113
        enabled = function()
          return vim.api.nvim_buf_get_option(0, 'modifiable')
        end,
        snippet = {
          expand = function(args)
            ls.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<C-E>'] = cmp.mapping(function(fallback)
              if ls.expand_or_jumpable() then
                ls.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<C-H>'] = cmp.mapping(function(fallback)
              if ls.jumpable(-1) then
                ls.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<C-K>'] = cmp.mapping(function(fallback)
              if ls.choice_active() then
                ls.change_choice(1)
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<C-J>'] = cmp.mapping(function(fallback)
              if ls.choice_active() then
                ls.change_choice(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
       }),
       sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'luasnip' },
         }, {
          { name = 'buffer' },
          { name = 'path' },
       }),
    })

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
          { name = 'path' },
        }, {
          { name = 'cmdline' },
        }),
      }
    )

    -- Set configuration for specific filetype.
    cmp.setup.filetype('gitcommit', {
      sources = cmp.config.sources({
            { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
        }, {
          { name = 'buffer' },
        })
      }
    )

    -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline({ "/", "?" }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
          { name = "buffer" }
        }
      }
    )
  end
}