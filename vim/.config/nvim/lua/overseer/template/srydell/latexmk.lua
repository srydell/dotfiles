return {
  name = 'latexmk',
  desc = 'Compile a tex file',
  builder = function()
    return {
      cmd = { 'latexmk' },
      args = { '-pv', '-output-directory=build' },
      components = {
        'default',
      },
    }
  end,
}
