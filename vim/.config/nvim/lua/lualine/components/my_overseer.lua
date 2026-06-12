-- ## Usage
--
--   require("lualine").setup({
--     sections = {
--       lualine_x = { "overseer" },
--     },
--   })
--
--   Or with options:
--   require("lualine").setup({
--     sections = {
--       lualine_x = { {"overseer", label = 'T:', colored = false} },
--     },
--   })
--
-- ## Options
--
-- *colored* (default: true)
--   Color the task icons.
--
-- *symbols*
--   Mapping of task status to symbol representation
--
-- *label* (default: '')
--   Prefix to put in front of task counts.
--
-- *unique* (default: false)
--   If true, ignore tasks with duplicate names.
--
-- *name* (default: nil)
--   String or list of strings. Only count tasks with this name or names.
--
-- *name_not* (default: false)
--   When true, count all tasks that do *not* match the 'name' param.
--
-- *status* (default: nil)
--   String or list of strings. Only count tasks with this status.
--
-- *status_not* (default: false)
--   When true, count all tasks that do *not* match the 'status' param.

local M = require('lualine.component'):extend()
local utils = require('lualine.utils.utils')
local status_values = { 'PENDING', 'RUNNING', 'CANCELED', 'SUCCESS', 'FAILURE', 'DISPOSED' }

local default_icons = {
  FAILURE = '󰅚 ',
  CANCELED = ' ',
  SUCCESS = '󰄴 ',
  RUNNING = '󰑮',
}
local default_no_icons = {
  FAILURE = 'F:',
  CANCELED = 'C:',
  SUCCESS = 'S:',
  RUNNING = 'R:',
}

function M:init(options)
  M.super.init(self, options)

  self.options.label = self.options.label or ''
  if self.options.colored == nil then
    self.options.colored = true
  end
  self.highlight_groups = {}
  self.symbols = vim.tbl_extend(
    'keep',
    self.options.symbols or {},
    self.options.icons_enabled ~= false and default_icons or default_no_icons
  )
end

function M:update_colors()
  self.highlight_groups = {}
  for _, status in ipairs(status_values) do
    local hl = string.format('Overseer%s', status)
    local color = { fg = utils.extract_color_from_hllist('fg', { hl }) }
    self.highlight_groups[status] = self:create_hl(color, status)
  end
end

function M:update_status()
  local task_list_loaded = package.loaded['overseer.task_list']
  local util_loaded = package.loaded['overseer.util']
  if not task_list_loaded or not util_loaded then
    return
  end

  if self.options.colored and not next(self.highlight_groups) then
    self:update_colors()
  end

  local tasks = task_list_loaded.list_tasks(self.options)
  local tasks_by_status = util_loaded.tbl_group_by(tasks, 'status')
  local pieces = {}
  if self.options.label ~= '' then
    table.insert(pieces, self.options.label)
  end
  for _, status in ipairs(status_values) do
    local status_tasks = tasks_by_status[status]
    if self.symbols[status] and status_tasks then
      if self.options.colored and self.highlight_groups[status] then
        local hl_start = self:format_hl(self.highlight_groups[status])
        table.insert(pieces, string.format('%s%s', hl_start, self.symbols[status]))
      else
        table.insert(pieces, string.format('%s', self.symbols[status]))
      end
    end
  end
  if #pieces > 0 then
    return table.concat(pieces, ' ')
  end
end

return M
