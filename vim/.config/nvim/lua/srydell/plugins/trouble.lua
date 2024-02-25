return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    local trouble = require('trouble')
    trouble.setup({
      auto_open = false,
      auto_close = false,
      auto_preview = true,
      auto_jump = {},
      mode = 'quickfix',
      severity = vim.diagnostic.severity.ERROR,
      cycle_results = false,
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = { 'XcodebuildBuildFinished', 'XcodebuildTestsFinished' },
      callback = function(event)
        if event.data.cancelled then
          return
        end

        if event.data.success then
          trouble.close()
        elseif not event.data.failedCount or event.data.failedCount > 0 then
          if next(vim.fn.getqflist()) then
            trouble.open({ focus = false })
          else
            trouble.close()
          end

          trouble.refresh()
        end
      end,
    })

    -- local function next()
    --   trouble.next({ skip_groups = false, jump = true })
    -- end
    --
    -- local function previous()
    --   trouble.previous({ skip_groups = true, jump = true })
    -- end
    --
    -- Move through the quickfix list
    -- vim.keymap.set('n', '<leader>q', '<cmd>TroubleToggle quickfix<CR>', { silent = true })
    -- vim.keymap.set('n', '[q', previous, { silent = true })
    -- vim.keymap.set('n', ']q', next, { silent = true })
    -- vim.keymap.set('n', '[Q', ':cfirst<CR>', { silent = true })
    -- vim.keymap.set('n', ']Q', ':clast<CR>', { silent = true })

    -- Move through the loclist
    -- vim.keymap.set('n', '<leader>l', '<cmd>TroubleToggle loclist<CR>', { silent = true })
    -- vim.keymap.set('n', '[l', previous, { silent = true })
    -- vim.keymap.set('n', ']l', next, { silent = true })
    -- vim.keymap.set('n', '[L', ':lfirst<CR>', { silent = true })
    -- vim.keymap.set('n', ']L', ':llast<CR>', { silent = true })
  end,
}
