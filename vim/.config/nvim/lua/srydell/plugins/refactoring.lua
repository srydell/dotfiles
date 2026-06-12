return {
  'ThePrimeagen/refactoring.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  keys = {
    {
      '<leader>rfe',
      function()
        require('refactoring').refactor('Extract Function')
      end,
      mode = 'x',
    },
    {
      '<leader>rfE',
      function()
        require('refactoring').refactor('Extract Function To File')
      end,
      mode = 'x',
    },
    {
      '<leader>rfi',
      function()
        require('refactoring').refactor('Inline Function')
      end,
      mode = 'n',
    },
    {
      '<leader>rvv',
      function()
        require('refactoring').refactor('Extract Variable')
      end,
      mode = 'x',
    },
    {
      '<leader>rvi',
      function()
        require('refactoring').refactor('Inline Variable')
      end,
      mode = { 'n', 'x' },
    },
    {
      '<leader>rpv',
      function()
        require('refactoring').debug.print_var()
      end,
      mode = { 'n', 'x' },
    },
    {
      '<leader>rpc',
      function()
        require('refactoring').debug.cleanup({})
      end,
      mode = 'n',
    },
    {
      '<leader>rpp',
      function()
        require('refactoring').debug.printf()
      end,
      mode = 'n',
    },
    {
      '<leader>rr',
      function()
        require('telescope').extensions.refactoring.refactors()
      end,
      mode = { 'n', 'x' },
    },
  },
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

    require('telescope').load_extension('refactoring')
  end,
}
