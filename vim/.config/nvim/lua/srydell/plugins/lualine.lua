return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', opts = {} },
  },
  config = function()
    local lualine = require('lualine')
    local overseer = require('overseer')

    -- Makes the background not change when changing mode
    -- What an insane feature
    local custom_gruvbox = require('lualine.themes.gruvbox')
    for _, name in pairs({ 'insert', 'visual', 'replace', 'command', 'inactive' }) do
      for _, component in pairs({ 'a', 'b', 'c' }) do
        custom_gruvbox[name][component].bg = custom_gruvbox.normal[component].bg
        custom_gruvbox[name][component].fg = custom_gruvbox.normal[component].fg
      end
    end

    local function get_compiler()
      local compiler = require('srydell.compiler.common').get_current_compiler()
      if not compiler then
        return '[]'
      end
      if vim.g.srydell_compiler_option ~= nil then
        return '[' .. compiler.name .. ' ' .. vim.g.srydell_compiler_option .. ']'
      end
      return '[' .. compiler.name .. ']'
    end

    lualine.setup({
      options = {
        icons_enabled = true,
        theme = custom_gruvbox,
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        lualine_a = {
          'branch',
          {
            'diagnostics',

            -- Table of diagnostic sources, available sources are:
            --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
            -- or a function that returns a table as such:
            --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
            sources = { 'nvim_diagnostic' },

            -- Displays diagnostics for the defined severity types
            sections = { 'error', 'warn', 'info', 'hint' },

            -- diagnostics_color = {
            --   -- Same values as the general color option can be used here.
            --   error = 'DiagnosticError', -- Changes diagnostics' error color.
            --   warn  = 'DiagnosticWarn',  -- Changes diagnostics' warn color.
            --   info  = 'DiagnosticInfo',  -- Changes diagnostics' info color.
            --   hint  = 'DiagnosticHint',  -- Changes diagnostics' hint color.
            -- },

            symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
            colored = false, -- Displays diagnostics status in color if set to true.
            update_in_insert = false, -- Update diagnostics in insert mode.
            always_visible = false, -- Show diagnostics even if there are none.
          },
        },
        lualine_b = { { 'filename', path = 1 } },
        lualine_c = { get_compiler },
        lualine_x = {
          {
            'my_overseer',
            label = '', -- Prefix for task counts
            colored = true, -- Color the task icons and counts
            symbols = {
              [overseer.STATUS.FAILURE] = '󰅚 ',
              [overseer.STATUS.CANCELED] = ' ',
              [overseer.STATUS.SUCCESS] = '󰄴 ',
              [overseer.STATUS.RUNNING] = '󰑮 ',
            },
            unique = true, -- Unique-ify non-running task count by name
            name = nil, -- List of task names to search for
            name_not = false, -- When true, invert the name search
            status = nil, -- List of task statuses to display
            status_not = false, -- When true, invert the status search
          },
        },
        lualine_y = { 'filetype' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {},
    })
  end,
}
