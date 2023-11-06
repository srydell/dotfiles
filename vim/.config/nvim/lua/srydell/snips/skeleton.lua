vim.api.nvim_create_autocmd("BufNewFile", {
    group = vim.api.nvim_create_augroup("vim-skeleton", { clear = true }),
    pattern = "*",
    callback = function()
      local status, skeleton = pcall(require, 'srydell.snips.skeleton.' .. vim.bo.ft)
      if not status then
        print('No skeleton file for ' .. 'srydell.snips.skeleton.' .. vim.bo.ft)
        return
      end

      if not skeleton.snip then
        print('Skeleton file found but no snippet named "snip" returned.')
        return
      end

      -- Expand the skeleton snippet
      require('luasnip').snip_expand(skeleton.snip)
    end
  })
