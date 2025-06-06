return {
  {
    'zbirenbaum/copilot.lua',
    dependencies = {
      'zbirenbaum/copilot-cmp',
      'olimorris/codecompanion.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    -- event = 'InsertEnter',
    config = function()
      require('copilot').setup({})
      require('copilot_cmp').setup({})
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
              completion_provider = 'cmp',
            },
          },
        },
      })
      local function chat()
        vim.cmd('CodeCompanionChat')
      end
      vim.keymap.set('n', '<leader>cc', chat, { silent = true })
    end,
  },
}
