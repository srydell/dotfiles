return {
  'stevearc/overseer.nvim',
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
          { 'display_duration', detail_level = 2 },
          'on_output_summarize',
          'on_exit_set_status',
          {
            'on_complete_notify',
            statuses = { 'FAILURE' },
          },
          'on_complete_dispose',
        },
      },
    })

    local function toggle()
      overseer.toggle({ direction = 'bottom' })
    end
    vim.keymap.set('n', '<leader>o', toggle)
  end,
}
