local docker_lldb = require('srydell.plugins.debugging.docker_lldb')

local containers =
  docker_lldb.parse_containers('abc123\twork-container\tcompany/dev:latest\n' .. 'def456\tpostgres\tpostgres:17\n')
assert(#containers == 2, 'expected two parsed containers')
assert(containers[1].id == 'abc123', 'container ID was not parsed')
assert(containers[1].name == 'work-container', 'container name was not parsed')
assert(containers[1].image == 'company/dev:latest', 'container image was not parsed')

local adapter = docker_lldb.executable_adapter('work-container', '/usr/bin/lldb-dap')
assert(adapter.type == 'executable', 'Docker LLDB adapter must use stdio')
assert(adapter.command == 'docker', 'Docker CLI is not the adapter launcher')
assert(vim.deep_equal(adapter.args, { 'exec', '-i', 'work-container', '/usr/bin/lldb-dap' }), 'wrong docker arguments')
assert(adapter.options.detached == false, 'docker exec must remain attached to DAP stdio')

local arguments = assert(docker_lldb.parse_arguments([[--mode fast --name "two words" 'literal value' escaped\ space]]))
assert(
  vim.deep_equal(arguments, { '--mode', 'fast', '--name', 'two words', 'literal value', 'escaped space' }),
  'shell-style arguments were parsed incorrectly'
)
assert(docker_lldb.parse_arguments([["unfinished]]) == nil, 'unterminated quotes must be rejected')

local missing = docker_lldb.missing_shared_libraries([[
	libfoo.so.2 => not found
	libc.so.6 => /usr/lib/libc.so.6 (0x00000000)
	libbar.so => not found
	libfoo.so.2 => not found
]])
assert(vim.deep_equal(missing, { 'libfoo.so.2', 'libbar.so' }), 'missing shared libraries were not parsed')

local problem = docker_lldb.format_problem('Missing tool.', 'Install it.', 'command not found')
assert(problem:find('How to fix it:', 1, true), 'diagnostic has no remediation heading')
assert(problem:find('Install it.', 1, true), 'diagnostic omitted remediation')
assert(problem:find('command not found', 1, true), 'diagnostic omitted command details')

print('docker_debugging: ok')
