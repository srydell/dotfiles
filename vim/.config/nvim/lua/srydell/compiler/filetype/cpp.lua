local function docker_compiler(target, edit_function)
  local docker = require('nvim-web-devicons').get_icon('Dockerfile', '')
  local tool_path = vim.fn.stdpath('config') .. '/tools/'
  return {
    name = docker .. ' ' .. target,
    tasks = {
      {
        task = 'docker run',
        command = { tool_path .. 'build_waf.sh', target },
      },
    },
    edit_compiler_option = edit_function,
  }
end

local function select_executable()
  local util = require('srydell.util')
  local files = util.split(io.popen('fd --no-ignore --type x --full-path ./build/debug/bin/'):read('*a'), '\n')
  table.foreach(files, function(index, file)
    -- './build/debug/bin/unit_test' -> { '.', 'build', 'debug', 'bin', 'unit_test' }
    local split = util.split(file, '/')
    -- { '.', 'build', 'debug', 'bin', 'unit_test' } -> 'unit_test'
    local executable = split[#split]
    files[index] = executable
  end)
  -- To build all targets
  table.insert(files, 'all')

  vim.ui.select(files, { prompt = 'Select executable' }, function(executable)
    if executable == nil then
      return
    end
    local common = require('srydell.compiler.common')
    common.replace_current_compiler(docker_compiler(executable, select_executable))
  end)
end

local function toggle_debug(current_compiler)
  -- current_compiler = {
  --   name = 'clang++ ' .. icons.building,
  --   tasks = { { task = 'clang++', will_do = 'RUN' } },
  -- }
  local icons = require('srydell.constants').icons
  local split = require('srydell.util').split(current_compiler.name, ' ')
  if current_compiler.tasks[1].will_do == 'RUN' then
    current_compiler.name = split[1] .. ' ' .. icons.debugging
    current_compiler.tasks[1].will_do = 'DEBUG'
  else
    current_compiler.name = split[1] .. ' ' .. icons.building
    current_compiler.tasks[1].will_do = 'RUN'
  end

  local common = require('srydell.compiler.common')
  common.replace_current_compiler(current_compiler)
end

local function get_compilers()
  local util = require('srydell.util')
  local project = util.get_project()
  if not project.name then
    return {}
  end

  local icons = require('srydell.constants').icons
  if util.contains({ 'dsf', 'oal', 'SPSCQueue' }, project.name) then
    return { docker_compiler('all', select_executable) }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    return {
      {
        name = 'clang++ ' .. icons.building,
        tasks = { { task = 'clang++', will_do = 'RUN' } },
        edit_compiler_option = toggle_debug,
      },
      {
        name = 'g++ ' .. icons.building,
        tasks = { { task = 'g++', will_do = 'RUN' } },
        edit_compiler_option = toggle_debug,
      },
    }
  end

  if util.contains({ 'tolc_prototype' }, project.name) then
    return {
      {
        name = './build.sh',
        tasks = { { task = 'tolc_prototype' } },
      },
    }
  end
  return {}
end

return get_compilers()
