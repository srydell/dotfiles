return {
  name = 'lua function',
  desc = 'Run the provided lua function as an overseer task',
  params = {
    f = {
      optional = false,
    },
  },
  builder = function(params)
    return {
      cmd = { 'true' },
      args = {},
      components = {
        -- Ensure the file is executable
        { 'srydell.on_exit_run_function', f = params.f },
      },
    }
  end,
}
