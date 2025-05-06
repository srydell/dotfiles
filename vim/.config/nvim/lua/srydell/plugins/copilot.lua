return {
  {
    'zbirenbaum/copilot.lua',
    dependencies = {
      { 'zbirenbaum/copilot-cmp' },
      { 'CopilotC-Nvim/CopilotChat.nvim', build = 'make tiktoken' },
    },
    -- cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({})
      require('copilot_cmp').setup({})
      require('CopilotChat').setup({})
    end,
  },
  -- {
  --   'CopilotC-Nvim/CopilotChat.nvim',
  --   dependencies = {
  --     { 'github/copilot.vim' },
  --     { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
  --   },
  --   build = 'make tiktoken',
  --   opts = {
  --     debug = false, -- Enable debugging
  --     -- See Configuration section for rest
  --   },
  --   -- See Commands section for default commands if you want to lazy load on them
  -- },
}
