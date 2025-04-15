return {
  name = 'manim',
  desc = 'Run a manim command.',
  params = {
    args = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
  },
  builder = function(params)
    local python = require('srydell.compiler.helpers.python')
    -- E.g.
    -- manim -pql main.py DefaultTemplate
    return {
      cmd = { 'manim' },
      args = {
        unpack(params.args),
      },
      components = {
        {
          'on_output_quickfix',
          open = true,
          errorformat = python.get_errorformat(),
        },
        'default',
      },
    }
  end,
}
