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
  local handle = io.popen('fd --no-ignore --type x --full-path ./build/debug/bin/')
  if not handle then
    return
  end
  local files = util.split(handle:read('*a'), '\n')
  handle:close()
  for index, file in ipairs(files) do
    -- './build/debug/bin/unit_test' -> { '.', 'build', 'debug', 'bin', 'unit_test' }
    local split = util.split(file, '/')
    -- { '.', 'build', 'debug', 'bin', 'unit_test' } -> 'unit_test'
    local executable = split[#split]
    files[index] = executable
  end
  -- To build all targets
  table.insert(files, 'all')

  -- To test all targets
  table.insert(files, 'test all')

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
  --   name = 'clang ' .. icons.building,
  --   tasks = { { task = 'clang', will_do = 'RUN' } },
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

  return current_compiler
end

local function toggle_perf_mode(current_compiler)
  if current_compiler.tasks[2].task == 'perf stat' then
    current_compiler.name = 'perf record'
    current_compiler.tasks[2].task = 'perf record'
  else
    current_compiler.name = 'perf stat'
    current_compiler.tasks[2].task = 'perf stat'
  end

  return current_compiler
end

local function perf_compiler()
  local executable = 'build/bin/' .. vim.fn.expand('%:t:r')
  return {
    name = 'perf stat',
    tasks = {
      { task = 'cpp perf compile', compiler = 'clang' },
      { task = 'perf stat', executable = executable },
    },
    edit_compiler_option = toggle_perf_mode,
  }
end

return function(ctx)
  local util = require('srydell.util')
  local project = ctx.project
  if not project.name then
    return {}
  end

  local icons = require('srydell.constants').icons
  if util.contains({ 'dsf', 'oal', 'SPSCQueue' }, project.name) then
    return { docker_compiler('all', select_executable) }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    local with_warnings = util.contains({ 'prototype' }, project.name)
    return {
      {
        name = 'clang++ ' .. icons.building,
        tasks = { { task = 'clang', will_do = 'RUN', with_warnings = with_warnings } },
        edit_compiler_option = toggle_debug,
      },
      {
        name = 'g++ ' .. icons.building,
        tasks = { { task = 'gcc', will_do = 'RUN', with_warnings = with_warnings } },
        edit_compiler_option = toggle_debug,
      },
      perf_compiler(),
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
