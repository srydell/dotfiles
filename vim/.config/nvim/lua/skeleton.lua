vim.api.nvim_create_autocmd("BufNewFile", {
    group = vim.api.nvim_create_augroup("vim-skeleton", { clear = true }),
    pattern = "*",
    callback = function()
      -- Make sure the snippets are loaded
      require('luasnip.loaders.from_lua').load({ paths = '~/.config/nvim/snips/' })

      -- Expand the '_skeleton' snippet on the go
      -- NOTE: It has to be marked 'hidden'
      local luasnip = require('luasnip')
      for _, snip in pairs(luasnip.get_snippets(vim.bo.ft)) do
        if snip.trigger == '_skeleton' and snip.hidden == true then
          luasnip.snip_expand(snip)
          return
        end
      end
    end
  })
