return {
  name = 'elixir script',
  builder = function()
    local path = './' .. vim.fn.expand('%')
    return {
      cmd = { 'elixir' },
      args = {
        path,
      },
      components = {
        { 'srydell.on_start_save_all' },
        {
          'on_output_quickfix',
          open_on_exit = 'always',
          errorformat = [[%Wwarning: %m,]]
            .. [[%C%f:%l,%Z,]]
            .. [[%E== Compilation error in file %f ==,]]
            .. [[%C** (%\w%\+) %f:%l: %m,%Z]],
        },
        'default',
      },
    }
  end,
}
