local util = require('srydell.plugins.debugging.util')
local message = util.format_problem('Missing adapter.', 'Install it.', 'not found')
assert(message:find('Details:', 1, true), 'debug diagnostic omitted details')
assert(message:find('How to fix it:', 1, true), 'debug diagnostic omitted remediation')

local dap = require('dap')
require('srydell.plugins.debugging.cpp').setup()
require('srydell.plugins.debugging.bash').setup()
require('srydell.plugins.debugging.python').setup()
require('srydell.plugins.debugging.swift').setup()

assert(type(dap.adapters.codelldb) == 'function', 'codelldb must be resolved when a session starts')
assert(type(dap.adapters.bashdb) == 'function', 'bash-debug-adapter must be resolved when a session starts')
assert(type(dap.adapters.python) == 'function', 'debugpy must be resolved when a session starts')
assert(type(dap.adapters.debugpy) == 'function', 'debugpy alias must use the guarded adapter')

if vim.uv.os_uname().sysname == 'Darwin' then
  assert(type(dap.adapters.codelldb_ios) == 'function', 'Swift adapter must be resolved when a session starts')
  assert(#(dap.configurations.swift or {}) > 0, 'Swift configuration was not registered on macOS')
else
  assert(dap.adapters.codelldb_ios == nil, 'iOS adapter must not be registered outside macOS')
  assert(dap.configurations.swift == nil, 'iOS configuration must not be registered outside macOS')
end

print('debugging_configs: ok')
