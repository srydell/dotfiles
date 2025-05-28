return {
  {
    'zbirenbaum/copilot.lua',
    dependencies = {
      -- { 'zbirenbaum/copilot-cmp' },
      { 'CopilotC-Nvim/CopilotChat.nvim', build = 'make tiktoken' },
    },
    -- event = 'InsertEnter',
    config = function()
      require('copilot').setup({})
      -- require('copilot_cmp').setup({})
      require('CopilotChat').setup({})
    end,
  },
}
