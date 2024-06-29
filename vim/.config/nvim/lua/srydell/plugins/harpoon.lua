return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup()

    -- Project specific
    local project = vim.fn.getcwd()

    -- basic telescope configuration
    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        })
        :find()
    end

    -- [f]ind [p]roject
    vim.keymap.set('n', '<leader>fp', function()
      toggle_telescope(harpoon:list(project))
    end, { desc = 'Open harpoon window' })

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
      harpoon:list(project):add()
    end)

    vim.keymap.set('n', ']f', function()
      harpoon:list(project):next()
    end)
    vim.keymap.set('n', '[f', function()
      harpoon:list(project):prev()
    end)
  end,
}
