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

local function is_cmake_project()
  return vim.fn.findfile('CMakeLists.txt', vim.fn.expand('%:p:h') .. ';') ~= ''
end

local function cmake_executable(build_dir, target)
  return build_dir .. '/' .. target
end

local function update_cmake_compiler(current_compiler, target)
  local build_dir = current_compiler.cmake.build_dir
  local executable = cmake_executable(build_dir, target)
  current_compiler.cmake.target = target
  current_compiler.tasks[2].target = target

  if current_compiler.cmake.kind == 'build' then
    current_compiler.name = 'cmake build ' .. target
  elseif current_compiler.cmake.kind == 'run' then
    current_compiler.name = 'cmake run ' .. target
    current_compiler.tasks[3].executable = executable
  elseif current_compiler.cmake.kind == 'perf stat' or current_compiler.cmake.kind == 'perf record' then
    current_compiler.name = 'cmake ' .. current_compiler.tasks[3].task .. ' ' .. target
    current_compiler.tasks[3].executable = executable
  end

  return current_compiler
end

local function edit_cmake_target(current_compiler)
  vim.ui.input({ prompt = 'CMake target: ', default = current_compiler.cmake.target }, function(input)
    if input == nil or input == '' then
      return
    end

    local common = require('srydell.compiler.common')
    common.replace_current_compiler(update_cmake_compiler(current_compiler, input))
  end)
end

local function cmake_compiler(kind, target)
  local build_dir = 'build'
  local compiler = {
    name = 'cmake ' .. kind .. ' ' .. target,
    cmake = {
      build_dir = build_dir,
      kind = kind,
      target = target,
    },
    tasks = {
      { task = 'cmake configure', build_dir = build_dir },
      { task = 'cmake build', build_dir = build_dir, target = target },
    },
    edit_compiler_option = edit_cmake_target,
  }

  if kind == 'run' then
    table.insert(compiler.tasks, { task = 'run executable', executable = cmake_executable(build_dir, target) })
  elseif kind == 'perf stat' or kind == 'perf record' then
    compiler.name = 'cmake ' .. kind .. ' ' .. target
    table.insert(compiler.tasks, { task = kind, executable = cmake_executable(build_dir, target) })
  end

  return compiler
end

local function cmake_compilers()
  local target = vim.fn.expand('%:t:r')
  return {
    cmake_compiler('build', target),
    cmake_compiler('run', target),
    cmake_compiler('perf stat', target),
    cmake_compiler('perf record', target),
  }
end

return function(ctx)
  local util = require('srydell.util')
  if is_cmake_project() then
    return cmake_compilers()
  end

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
