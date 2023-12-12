return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup()

    -- Project specific
    local project = vim.fn.getcwd()

    vim.keymap.set('n', '<leader>xx', function()
      harpoon.ui:toggle_quick_menu(harpoon:list(project))
    end)

    -- Removes the list alltogether drop f
    vim.keymap.set('n', '<leader>xdF', function()
      harpoon:list(project):clear()
    end)
    -- Removes one file from list
    vim.keymap.set('n', '<leader>xdf', function()
      harpoon:list(project):remove()
    end)
    vim.keymap.set('n', '<leader>xf', function()
      harpoon:list(project):append()
    end)

    vim.keymap.set('n', ']f', function()
      harpoon:list(project):next()
    end)
    vim.keymap.set('n', '[f', function()
      harpoon:list(project):prev()
    end)
  end,
}
