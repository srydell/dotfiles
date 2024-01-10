local function get_compilers()
  local util = require('srydell.util')
  local project = util.get_project()
  if not project.name then
    return {}
  end

  if util.contains({ 'dsf', 'oal' }, project.name) then
    return {
      {
        name = 'rsync bx',
        tasks = { { 'rsync', project = project.name } },
        type = 'overseer',
      },
    }
  end
  return {}
end

return get_compilers()
