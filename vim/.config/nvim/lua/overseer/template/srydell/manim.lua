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
    -- E.g.
    -- manim -pql main.py DefaultTemplate
    return {
      cmd = { 'manim' },
      args = {
        unpack(params.args),
      },
      components = {
        { 'srydell.on_start_save_all' },
        { 'srydell.on_start_run_sh', cmd = '. ./venv/bin/activate' },
        { 'on_output_parse', parser = require('srydell.compiler.helpers.python_parser').new_parser() },
        { 'on_result_diagnostics_quickfix', open = true },
        'default',
      },
    }
  end,
}
