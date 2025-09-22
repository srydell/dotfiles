return {
  name = 'sh',
  builder = function()
    local path = './' .. vim.fn.expand('%')
    return {
      cmd = { path },
      args = {},
      components = {
        { 'srydell.on_start_save_all' },
        -- Ensure the file is executable
        { 'srydell.on_start_run_sh', cmd = 'chmod +x ' .. path },
        {
          'on_output_quickfix',
          open_on_match = true,
          errorformat = [[%f: line %l: %m,]] .. [[%f: %l: %m]],
        },
        'default',
      },
    }
  end,
}
