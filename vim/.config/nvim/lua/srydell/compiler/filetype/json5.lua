local function get_compilers()
  local util = require('srydell.util')
  local project = util.get_project()
  if not project.name then
    return {}
  end

  if util.contains({ 'dsf', 'oal' }, project.name) then
    local constants = require('srydell.constants')
    return {
      {
        name = 'rsync ' .. constants.icons.building,
        tasks = { { task = 'rsync', project = project.name } },
      },
    }
  end
  return {}
end

return get_compilers()
