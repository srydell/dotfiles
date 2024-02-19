local util = require('srydell.util')

return {
  'mfussenegger/nvim-lint',
  event = {
    'BufReadPre',
    'BufNewFile',
  },
  config = function()
    local lint = require('lint')

    -- swiftlint
    local pattern = '[^:]+:(%d+):(%d+): (%w+): (.+)'
    local groups = { 'lnum', 'col', 'severity', 'message' }
    local defaults = { ['source'] = 'swiftlint' }
    local severity_map = {
      ['error'] = vim.diagnostic.severity.ERROR,
      ['warning'] = vim.diagnostic.severity.WARN,
    }

    lint.linters.swiftlint = {
      cmd = 'swiftlint',
      stdin = false,
      args = {
        'lint',
        '--force-exclude',
        '--use-alternative-excluding',
        '--config',
        function()
          return util.find_config('.swiftlint.yml') or os.getenv('HOME') .. '/.config/nvim/.swiftlint.yml' -- change path if needed
        end,
      },
      stream = 'stdout',
      ignore_exitcode = true,
      parser = require('lint.parser').from_pattern(pattern, groups, severity_map, defaults),
    }

    -- setup
    lint.linters_by_ft = {
      -- cmake = { 'cmakelint' },
      python = { 'ruff' },
      swift = { 'swiftlint' },
      -- sh = { 'shellcheck' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- vim.keymap.set('n', '<leader>l', function()
    --   lint.try_lint()
    -- end, { desc = 'Trigger linting for current file' })
  end,
}
