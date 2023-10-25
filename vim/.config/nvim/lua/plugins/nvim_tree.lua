return
{
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', opts = {} }
  },
  config = function ()
    local tree = require('nvim-tree')

    -- Toggle visibility of nvim tree
    vim.keymap.set("n", "<leader><leader>t", "<cmd>NvimTreeToggle<CR>", { silent = true, desc = "Toggle neovim tree" })

    tree.setup({
        actions = {
          open_file = {
            quit_on_open = true,
          }
        }
      })
  end
}
