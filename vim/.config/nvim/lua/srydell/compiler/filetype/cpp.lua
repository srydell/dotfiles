local util = require('srydell.util')

local function get_compilers()
  local project = util.get_project()
  if not project.name then
    return {}
  end

  local icons = require('srydell.constants').icons
  if util.contains({ 'dsf', 'oal', 'SPSCQueue' }, project.name) then
    return {
      {
        name = 'git ' .. icons.up .. icons.down .. ' ' .. icons.building,
        tasks = { { 'git push' } },
        type = 'overseer',
      },
      {
        name = 'rsync ' .. icons.building,
        tasks = { { 'rsync', project = project.name } },
        type = 'overseer',
      },
    }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    return {
      {
        name = 'clang++ ' .. icons.building,
        tasks = { { 'clang++', will_do = 'RUN' } },
        type = 'overseer',
      },
      {
        name = 'clang++ ' .. icons.debugging,
        tasks = { { 'clang++', will_do = 'DEBUG' } },
        type = 'overseer',
      },
      {
        name = 'g++ ' .. icons.building,
        tasks = { { 'g++', will_do = 'RUN' } },
        type = 'overseer',
      },
      {
        name = 'g++ ' .. icons.debugging,
        tasks = { { 'g++', will_do = 'DEBUG' } },
        type = 'overseer',
      },
    }
  end

  return {}
end

return get_compilers()
