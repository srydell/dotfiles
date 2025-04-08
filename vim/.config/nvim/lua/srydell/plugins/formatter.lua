local util = require('srydell.util')

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      '<leader>f',
      function()
        require('conform').format({ async = true, lsp_fallback = true })
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  -- Everything in opts will be passed to setup()
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      cmake = { 'cmake_format' },
      cpp = { 'clang_format' },
      lua = { 'stylua' },
      python = { 'ruff_format' },
      swift = { 'swiftformat_ext' },
      tex = { 'tex_fmt' },
    },
    -- Set up format-on-save
    format_on_save = function()
      if vim.bo.ft == 'java' then
        return
      end

      if vim.bo.ft == 'cpp' then
        if util.current_path_contains('dsf') or util.current_path_contains('oal') then
          return
        end
      end

      -- ...additional logic...
      return { timeout_ms = 500, lsp_fallback = true }
    end,

    -- Customize formatters
    formatters = {
      stylua = {
        prepend_args = { '--config-path', vim.fn.stdpath('config') .. '/stylua.toml' },
      },
      tex_fmt = {
        -- https://github.com/WGUNDERWOOD/tex-fmt/releases/tag/v0.4.3
        command = 'tex-fmt',
        args = { '--stdin' },
        stdin = true,
      },
      shfmt = {
        prepend_args = { '-i', '2' },
      },
      swiftformat_ext = {
        command = 'swiftformat',
        args = function(self, _)
          return {
            '--config',
            util.find_config('.swiftformat') or vim.fn.stdpath('config') .. '/.swiftformat',
            '--stdinpath',
            '$FILENAME',
          }
        end,
        range_args = function(self, ctx)
          return {
            '--config',
            util.find_config('.swiftformat') or '~/.config/nvim/.swiftformat',
            '--linerange',
            ctx.range.start[1] .. ',' .. ctx.range['end'][1],
          }
        end,
        stdin = true,
        condition = function(self, ctx)
          return vim.fs.basename(ctx.filename) ~= 'README.md'
        end,
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require('conform').formatexpr()"
  end,
}
