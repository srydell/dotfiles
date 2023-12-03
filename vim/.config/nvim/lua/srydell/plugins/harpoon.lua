return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup()

    -- Project specific
    local project = vim.fn.getcwd()

    -- Removes the list alltogether
    vim.keymap.set('n', '<leader>xF', function()
      harpoon:list(project):clear()
    end)
    vim.keymap.set('n', '<leader>xf', function()
      harpoon:list(project):append()
    end)
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list(project))
    end)

    vim.keymap.set('n', ']f', function()
      harpoon:list(project):next()
    end)
    vim.keymap.set('n', '[f', function()
      harpoon:list(project):prev()
    end)
  end,
}
