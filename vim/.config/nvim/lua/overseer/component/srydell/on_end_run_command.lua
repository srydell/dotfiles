return {
  desc = 'If a task exits with code 0, run a command as a new overseer task',
  params = {
    name = {
      type = 'string',
      optional = true,
      default = 'run command',
    },
    cmd = {
      type = 'list',
      optional = false,
      subtype = { type = 'string' },
    },
    args = {
      type = 'list',
      optional = true,
      default = {},
      subtype = { type = 'string' },
    },
  },
  constructor = function(params)
    return {
      on_exit = function(self, _task, code)
        if code ~= 0 then
          return
        end

        local task = require('overseer').new_task({
          name = params.name,
          cmd = params.cmd,
          args = params.args,
          components = { { 'on_output_quickfix', open = true }, 'default' },
        })
        task:start()
      end,
    }
  end,
}
