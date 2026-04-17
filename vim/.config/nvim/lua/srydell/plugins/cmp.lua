return {
  'saghen/blink.cmp',
  version = '1.*',
  dependencies = {
    { 'saghen/blink.compat', version = '2.*', opts = {} },
    'hrsh7th/cmp-nvim-lua',
    'rcarriga/cmp-dap',
    'L3MON4D3/LuaSnip',
    'zbirenbaum/copilot-cmp',
  },
  opts = function()
    return {
      enabled = function()
        local is_dap_buffer = vim.tbl_contains({ 'dap-repl', 'dapui_watches', 'dapui_hover' }, vim.bo.filetype)
        local dap_req = vim.api.nvim_get_option_value('buftype', {}) ~= 'prompt' or is_dap_buffer
        local modifiable = vim.api.nvim_get_option_value('modifiable', {})
        return dap_req and modifiable
      end,
      snippets = {
        preset = 'luasnip',
      },
      completion = {
        trigger = {
          show_in_snippet = false,
        },
      },
      keymap = {
        preset = 'none',
        ['<C-y>'] = { 'select_and_accept', 'fallback' },
        ['<C-b>'] = { function(cmp) cmp.scroll_documentation_up(4) end, 'fallback' },
        ['<C-f>'] = { function(cmp) cmp.scroll_documentation_down(4) end, 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
      },
      sources = {
        default = { 'lsp', 'copilot', 'nvim_lua', 'snippets', 'buffer', 'path' },
        per_filetype = {
          gitcommit = { 'buffer' },
          codecompanion = { 'codecompanion' },
          codecompanion_input = { 'codecompanion' },
          ['dap-repl'] = { 'dap' },
          dapui_watches = { 'dap' },
          dapui_hover = { 'dap' },
        },
        providers = {
          copilot = {
            name = 'copilot',
            module = 'blink.compat.source',
          },
          nvim_lua = {
            name = 'nvim_lua',
            module = 'blink.compat.source',
          },
          dap = {
            name = 'dap',
            module = 'blink.compat.source',
          },
        },
      },
      cmdline = {
        keymap = {
          preset = 'inherit',
        },
        completion = {
          menu = {
            auto_show = true,
          },
        },
        sources = function()
          local cmd_type = vim.fn.getcmdtype()
          if cmd_type == '/' or cmd_type == '?' then
            return { 'buffer' }
          end
          return { 'path', 'cmdline' }
        end,
      },
    }
  end,
  config = function(_, opts)
    require('copilot_cmp').setup({})

    local blink = require('blink.cmp')
    blink.setup(opts)

    vim.keymap.set({ 'i', 's' }, '<C-E>', function()
      local ls = require('luasnip')
      if ls.expandable() then
        ls.expand()
      elseif ls.locally_jumpable(1) then
        ls.jump(1)
      end
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<C-H>', function()
      local ls = require('luasnip')
      if ls.locally_jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<C-K>', function()
      local ls = require('luasnip')
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<C-J>', function()
      local ls = require('luasnip')
      if ls.choice_active() then
        ls.change_choice(-1)
      end
    end, { silent = true })
  end,
}
