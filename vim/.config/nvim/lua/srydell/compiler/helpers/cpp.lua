local util = require('srydell.util')

local M = {}

-- Diagnostic/output parsing for clang++/g++ has moved to a pure-Lua parser:
-- see srydell.compiler.helpers.cpp_parser (built on overseer.parselib)
-- instead of a vim errorformat string.

M.get_flags = function(compiler, with_warnings)
  local flags = {
    '-pthread',
    '-std=c++23',
  }
  if with_warnings then
    flags = util.merge(flags, {
      '-Wall',
      '-Werror',
      '-Wextra',
      '-Wshadow',
      '-Wnon-virtual-dtor',
      '-Wold-style-cast',
      '-Wcast-align',
      '-Wunused',
      '-Woverloaded-virtual',
      '-Wpedantic',
      '-Wconversion',
      '-Wsign-conversion',
      '-Wnull-dereference',
      '-Wdouble-promotion',
      '-Wdate-time',
      '-Wformat=2',
    })
  end
  local extra_flags = {}
  if compiler == 'clang' then
    extra_flags = { '--debug', '-fsanitize=address', '-Wduplicate-enum', '-fdiagnostics-absolute-paths' }

    -- extra_flags = { '--debug', '-fsanitize=thread', '-Wduplicate-enum', '-fdiagnostics-absolute-paths' }
  elseif compiler == 'gcc' then
    extra_flags = {
      '-g',
      '-Og',
      -- NOTE: ARM asan for gcc not supported as of writing this.
      --       On support, uncomment below:
      -- '-fsanitize=address', '-fno-omit-frame-pointer',
      '-Werror=unused-variable',
    }
  end
  return util.merge(flags, extra_flags)
end

M.get_args = function(compiler, full_path_to_file, out_executable, with_warnings)
  return util.merge({ full_path_to_file, '-o', out_executable }, M.get_flags(compiler, with_warnings))
end

M.get_perf_flags = function(compiler)
  local flags = {
    '-pthread',
    '-std=c++23',
    '-O2',
    '-g',
  }
  if compiler == 'clang' then
    return util.merge(flags, { '-fno-omit-frame-pointer', '-fdiagnostics-absolute-paths' })
  end
  return util.merge(flags, { '-fno-omit-frame-pointer' })
end

M.get_perf_args = function(compiler, full_path_to_file, out_executable)
  return util.merge({ full_path_to_file, '-o', out_executable }, M.get_perf_flags(compiler))
end

return M
