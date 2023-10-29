vim.api.nvim_create_autocmd("BufNewFile", {
    group = vim.api.nvim_create_augroup("vim-skeleton", { clear = true }),
    pattern = "*",
    callback = function()
      local status, skeleton = pcall(require, 'srydell.snips.skeleton.' .. vim.bo.ft)
      if (not status) then
        print('No skeleton file')
        return
      end

      if not skeleton.snip then
        print('Skeleton file found but no snippet named "snip" returned.')
        return
      end

      -- Expand the skeleton snippet
      local ls = require('luasnip')
      ls.snip_expand(skeleton.snip)
    end
  })
