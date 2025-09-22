return {
  name = 'latexmk',
  desc = 'Compile a tex file',
  builder = function()
    return {
      cmd = { 'latexmk' },
      args = { '-pv', '-output-directory=build' },
      components = {
        { 'srydell.on_start_save_all' },
        'default',
      },
    }
  end,
}
