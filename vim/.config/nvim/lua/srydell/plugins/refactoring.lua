return {
  'ThePrimeagen/refactoring.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  lazy = false,
  config = function()
    local refactoring = require('refactoring')
    refactoring.setup({
      -- overriding printf statement for cpp
      printf_statements = {
        -- add a custom printf statement for cpp
        cpp = {
          'std::cout << "%s" << std::endl;',
        },
      },
      print_var_statements = {
        -- add a custom print var statement for cpp
        cpp = {
          'std::cout << "%s " << %s;',
        },
      },
      -- prompt for return type
      prompt_func_return_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
      },
      -- prompt for function parameters
      prompt_func_param_type = {
        go = true,
        cpp = true,
        c = true,
        java = true,
      },
    })

    -- Extract function supports only visual mode
    vim.keymap.set('x', '<leader>rfe', function()
      refactoring.refactor('Extract Function')
    end)
    vim.keymap.set('x', '<leader>rfE', function()
      refactoring.refactor('Extract Function To File')
    end)
    vim.keymap.set('n', '<leader>rfi', function()
      refactoring.refactor('Inline Function')
    end)

    -- Extract variable supports only visual mode
    vim.keymap.set('x', '<leader>rvv', function()
      refactoring.refactor('Extract Variable')
    end)
    vim.keymap.set({ 'n', 'x' }, '<leader>rvi', function()
      refactoring.refactor('Inline Variable')
    end)

    -- Printing
    vim.keymap.set({ 'x', 'n' }, '<leader>rpv', function()
      require('refactoring').debug.print_var()
    end)
    vim.keymap.set('n', '<leader>rpc', function()
      refactoring.debug.cleanup({})
    end)
    vim.keymap.set('n', '<leader>rpp', function()
      require('refactoring').debug.printf()
    end)

    require('telescope').load_extension('refactoring')

    vim.keymap.set({ 'n', 'x' }, '<leader>rr', function()
      require('telescope').extensions.refactoring.refactors()
    end)
  end,
}
