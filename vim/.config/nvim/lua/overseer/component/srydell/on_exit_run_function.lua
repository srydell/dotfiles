return {
  desc = 'On exit, run provided lua function',
  params = {
    f = {
      optional = false,
    },
  },
  constructor = function(params)
    return {
      on_exit = function(self, task, code)
        local ternary = require('srydell.util').ternary
        -- NOTE: If f returns nil, it's a FAILURE
        local out = params.f()
        if out == nil then
          vim.notify('Provided function returns nil, it will fail the pipeline', vim.log.levels.ERROR)
        end
        task:finalize(ternary(out, 'SUCCESS', 'FAILURE'))
      end,
    }
  end,
}
