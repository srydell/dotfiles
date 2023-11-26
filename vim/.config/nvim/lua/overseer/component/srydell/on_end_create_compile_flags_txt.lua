return {
  desc = 'On successful run, create a compile_flags.txt with some parameter flags',
  -- Define parameters that can be passed in to the component
  params = {
    flags = {
      type = 'string',
      optional = false,
    },
  },
  constructor = function(params)
    return {
      on_exit = function(self, task, code)
        -- Called when the task command has completed
        if code == 0 then
          local data = assert(io.open('./compile_flags.txt', 'w'))
          data:write(params.flags)
          data:close()
        end
      end,
    }
  end,
}
