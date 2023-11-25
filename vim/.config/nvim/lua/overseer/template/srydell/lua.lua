return {
  name = 'lua',
  builder = function()
    local path = './' .. vim.fn.expand('%')
    return {
      cmd = { 'lua' },
      args = {
        path,
      },
      components = {
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = [[%s: %f:%l:%m]],
        },
        'default',
      },
    }
  end,
}
