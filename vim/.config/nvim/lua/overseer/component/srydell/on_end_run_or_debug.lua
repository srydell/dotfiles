return {
  desc = 'If a task exits with code 0, run or call dap.debug on the file',
  -- Define parameters that can be passed in to the component
  params = {
    executable = {
      type = 'string',
      optional = false,
    },
    will_do = {
      type = 'enum',
      optional = false,
      choices = { 'RUN', 'DEBUG' },
    },
  },
  constructor = function(params)
    return {
      on_exit = function(self, _task, code)
        if code == 0 then
          if params.will_do == 'RUN' then
            local exe = require('overseer').new_task({
              cmd = { params.executable },
              args = {},
              components = { { 'on_output_quickfix', open = true }, 'default' },
            })
            exe:start()
          else
            local dap = require('dap')
            if dap.configurations[vim.bo.filetype] then
              local config = dap.configurations[vim.bo.filetype][1]
              config.program = params.executable
              dap.run(config)
            else
              vim.print('There is no dap configuration for filetype = ' .. vim.bo.filetype)
            end
          end
        end
      end,
    }
  end,
}
