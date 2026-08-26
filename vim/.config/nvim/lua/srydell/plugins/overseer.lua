return {
  'stevearc/overseer.nvim',
  event = 'VeryLazy',
  config = function()
    local overseer = require('overseer')
    local util = require('srydell.util')
    -- Each template is in lua/overseer/template/srydell/<name>.lua
    local templates = { 'shell' }
    for _, filepath in ipairs(vim.api.nvim_get_runtime_file('lua/overseer/template/srydell/*.lua', true)) do
      -- /Users/simryd/file.lua -> { Users, simryd, template_name.lua }
      local paths = util.split(filepath, '/')
      -- { Users, simryd, template_name.lua } ->  template_name.lua
      local filename = paths[#paths]
      -- template_name.lua -> srydell.template_name
      table.insert(templates, 'srydell.' .. filename:sub(1, -5))
    end
    overseer.setup({
      templates = templates,
      component_aliases = {
        -- Most tasks are initialized with the default components
        -- Overwrite them to only notify on failure
        default = {
          'on_exit_set_status',
          {
            'on_complete_notify',
            statuses = { 'FAILURE' },
          },
          'on_complete_dispose',
        },
      },
    })

    -- Resolve a task down to the buffer that actually holds runnable output.
    -- Compiler tasks are wrapped in an 'orchestrator' strategy (see
    -- common.lua's M.run), whose own bufnr is just a synthetic status table
    -- ("SUCCESS python3 ..." etc.), not real stdout -- so recurse into its
    -- sub-tasks (last one first, since that's the one most likely to hold
    -- the interesting output, e.g. the actual `python3 file.py` run) to find
    -- the innermost non-orchestrator task's buffer.
    local function resolve_output_bufnr(task)
      local strategy_tasks = task.strategy and task.strategy.tasks
      if not strategy_tasks or vim.tbl_isempty(strategy_tasks) then
        return task:get_bufnr()
      end
      local task_list = require('overseer.task_list')
      for i = #strategy_tasks, 1, -1 do
        local ids = strategy_tasks[i]
        for j = #ids, 1, -1 do
          local sub_task = task_list.get(ids[j])
          if sub_task then
            local bufnr = resolve_output_bufnr(sub_task)
            if bufnr then
              return bufnr
            end
          end
        end
      end
      return task:get_bufnr()
    end

    local function toggle()
      -- Close every currently-open OverseerOutput window first (there may
      -- be more than one lingering from previous runs, since each run opens
      -- a fresh split rather than reusing an old one).
      if require('srydell.compiler.output_window').close_all() then
        return
      end

      local task_list = require('overseer.task_list')
      local tasks = task_list.list_tasks({ unique = true })
      local task = tasks[1]
      if not task then
        vim.notify('No overseer tasks yet', vim.log.levels.WARN)
        return
      end

      local bufnr = resolve_output_bufnr(task)
      if not bufnr then
        vim.notify('Task has no output buffer', vim.log.levels.WARN)
        return
      end
      vim.cmd.split()
      vim.api.nvim_win_set_buf(0, bufnr)
      require('overseer.util').set_term_window_opts()
      require('overseer.util').scroll_to_end(0)
    end
    vim.keymap.set('n', '<leader>o', toggle)
  end,
}
