local function get_compilers()
  local util = require('srydell.util')

  local function find_exe_files()
    local files = util.split(io.popen('fd --no-ignore --type x --full-path ./build/debug/bin/'):read('*a'), '\n')
    vim.ui.select(files, { prompt = 'Select executable' }, function(chosen_file)
      -- './build/debug/bin/unit_test' -> { '.', 'build', 'debug', 'bin', 'unit_test' }
      local split = util.split(chosen_file, '/')
      -- { '.', 'build', 'debug', 'bin', 'unit_test' } -> 'unit_test'
      local executable = split[#split]
      local options = require('srydell.compiler.options')
      options.set_compiler_option(executable)
    end)
  end

  local project = util.get_project()
  if not project.name then
    return {}
  end

  local icons = require('srydell.constants').icons
  if util.contains({ 'dsf', 'oal', 'SPSCQueue' }, project.name) then
    local docker = require('nvim-web-devicons').get_icon('Dockerfile', '')
    local tool_path = vim.fn.stdpath('config') .. '/tools/'
    local options = require('srydell.compiler.options')
    local compiler_with_option = 'docker exe'
    options.set_compiler_option_generator(find_exe_files, compiler_with_option)
    return {
      {
        name = 'docker all',
        tasks = { { task = 'docker run', command = { tool_path .. 'build_waf.sh' } } },
      },
      {
        name = compiler_with_option,
        tasks = { { task = 'docker run', command = { tool_path .. 'build_waf_target.sh' }, with_option = true } },
      },
    }
  end

  if util.contains({ 'prototype', 'leetcode' }, project.name) then
    return {
      {
        name = 'clang++ ' .. icons.building,
        tasks = { { task = 'clang++', will_do = 'RUN' } },
      },
      {
        name = 'clang++ ' .. icons.debugging,
        tasks = { { task = 'clang++', will_do = 'DEBUG' } },
      },
      {
        name = 'g++ ' .. icons.building,
        tasks = { { task = 'g++', will_do = 'RUN' } },
      },
      {
        name = 'g++ ' .. icons.debugging,
        tasks = { { task = 'g++', will_do = 'DEBUG' } },
      },
    }
  end

  return {}
end

return get_compilers()
