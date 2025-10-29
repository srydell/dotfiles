local util = require('srydell.util')

local M = {}

-- Errorformat for gcc/clang
M.get_errorformat = function()
  return [[%*[^"]"%f"%*\D%l:%c: %m,]]
    .. [[%*[^"]"%f"%*\D%l: %m,]]
    .. [[\"%f"%*\D%l:%c: %m,]]
    .. [[\"%f"%*\D%l: %m,]]
    .. [[%-G%f:%l: %trror: (Each undeclared identifier is reported only once,]]
    .. [[%-G%f:%l: %trror: for each function it appears in.),]]
    .. [[%f:%l:%c: %trror: %m,]]
    .. [[%f:%l:%c: %tarning: %m,]]
    .. [[%f:%l:%c: %m,]]
    .. [[%f:%l: %trror: %m,]]
    .. [[%f:%l: %tarning: %m,]]
    .. [[%f:%l: %m,]]
    .. [[%f:\(%*[^\)]\): %m,]]
    .. [[\"%f"\, line %l%*\D%c%*[^ ] %m,]]
    .. [[%D%*\a[%*\d]: Entering directory [`']%f',]]
    .. [[%X%*\a[%*\d]: Leaving directory [`']%f',]]
    .. [[%D%*\a: Entering directory [`']%f',]]
    .. [[%X%*\a: Leaving directory [`']%f',]]
    .. [[%DMaking %*\a in %f,]]
end

M.get_flags = function(compiler, with_warnings)
  local flags = {
    '-pthread',
    '-std=c++23',
  }
  if with_warnings then
    flags = {
      unpack(flags),
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
    }
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

return M
