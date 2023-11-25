local util = require('srydell.util')

local function get_compilers()
  local project = util.get_project()
  if not project.name then
    return {}
  end

  if util.contains({ 'dsf', 'oal' }, project.name) then
    return { { name = 'rsync bx', tasks = { { 'rsync', project = project.name } } } }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    return {
      { name = 'clang++ 🔨', tasks = { { 'clang++', will_do = 'RUN' } } },
      { name = 'clang++ 🐛', tasks = { { 'clang++', will_do = 'DEBUG' } } },
      { name = 'g++ 🔨', tasks = { { 'g++', will_do = 'RUN' } } },
      { name = 'g++ 🐛', tasks = { { 'g++', will_do = 'DEBUG' } } },
    }
  end

  return {}
end

return get_compilers()
