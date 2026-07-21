return {
  {
    'zbirenbaum/copilot.lua',
    cmd = { 'CodeCompanion', 'CodeCompanionChat' },
    dependencies = {
      'olimorris/codecompanion.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    event = 'InsertEnter',
    keys = {
      { '<leader>cc', '<cmd>CodeCompanionChat<CR>', mode = 'n', silent = true },
    },
    config = function()
      require('copilot').setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
      require('codecompanion').setup({
        strategies = {
          chat = {
            roles = {
              ---The header name for the LLM's messages
              ---@type string|fun(adapter: CodeCompanion.Adapter): string
              llm = function(adapter)
                return 'CodeCompanion (' .. adapter.formatted_name .. ')'
              end,

              ---The header name for your messages
              ---@type string
              user = 'Me',
            },
            opts = {
              completion_provider = 'blink',
            },
          },
        },
      })
    end,
  },
}
