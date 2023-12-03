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
      javascript = { { 'prettierd', 'prettier' } },
      lua = { 'stylua' },
      python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'ruff_format' }
        else
          return { 'isort', 'black' }
        end
      end,
      swift = { 'swiftformat_ext' },
    },
    -- Set up format-on-save
    format_on_save = function()
      local project = util.get_project()
      if project.name == 'dsf' then
        return
      end

      -- ...additional logic...
      return { timeout_ms = 500, lsp_fallback = true }
    end,

    -- Customize formatters
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2' },
      },
      swiftformat_ext = {
        command = 'swiftformat',
        args = function()
          return {
            '--config',
            util.find_config('.swiftformat') or '~/.config/nvim/.swiftformat', -- update fallback path if needed
            '--stdinpath',
            '$FILENAME',
          }
        end,
        range_args = function(ctx)
          return {
            '--config',
            util.find_config('.swiftformat') or '~/.config/nvim/.swiftformat', -- update fallback path if needed
            '--linerange',
            ctx.range.start[1] .. ',' .. ctx.range['end'][1],
          }
        end,
        stdin = true,
        condition = function(ctx)
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