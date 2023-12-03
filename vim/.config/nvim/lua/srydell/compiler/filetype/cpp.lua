local util = require('srydell.util')

local function get_compilers()
  local project = util.get_project()
  if not project.name then
    return {}
  end

  if util.contains({ 'dsf', 'oal' }, project.name) then
    return {
      { name = 'rsync bx', tasks = { { 'rsync', project = project.name } }, type = 'overseer' },
    }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    return {
      { name = 'clang++ 🔨', tasks = { { 'clang++', will_do = 'RUN' } }, type = 'overseer' },
      { name = 'clang++ 🐛', tasks = { { 'clang++', will_do = 'DEBUG' } }, type = 'overseer' },
      { name = 'g++ 🔨', tasks = { { 'g++', will_do = 'RUN' } }, type = 'overseer' },
      { name = 'g++ 🐛', tasks = { { 'g++', will_do = 'DEBUG' } }, type = 'overseer' },
    }
  end

  return {}
end

return get_compilers()
