-- Run from the nvim directory: nvim --headless -u NONE -l tests/skeleton_templates.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
for _, plugin in ipairs({ 'LuaSnip', 'plenary.nvim' }) do
  vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/' .. plugin)
end
local ls = require('luasnip')
local root = vim.fn.tempname()

local function render(ft, path)
  if ls.session.current_nodes[vim.api.nvim_get_current_buf()] then
    ls.unlink_current()
  end
  vim.cmd('enew!')
  vim.api.nvim_buf_set_name(0, root .. '/' .. path)
  local module = 'srydell.snips.skeleton.' .. ft
  package.loaded[module] = nil
  local snippet = require(module).snip
  if not snippet then
    return nil
  end
  ls.snip_expand(snippet)
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
end

local compiler = render('lua', 'lua/srydell/compiler/filetype/example.lua')
local resolver = assert(loadstring(compiler))()
assert(type(resolver) == 'function', 'compiler skeleton must export a resolver')
local compilers = resolver({ file = 'first.lua' })
assert(compilers[1].tasks.task == 'Name corresponding to overseer template')
assert(resolver({ file = 'second.lua' }) ~= compilers, 'resolver must return fresh compiler tables')

-- Exercise template editing and task conversion through the real compiler loader.
vim.bo.filetype = 'skeleton_test'
package.preload['srydell.compiler.filetype.skeleton_test'] = function()
  return resolver
end
local expected = vim.fn.stdpath('config')
  .. '/lua/overseer/template/srydell/Name_corresponding_to_overseer_template.lua'
local old_readable, old_cmd = vim.fn.filereadable, vim.cmd
local edited
vim.fn.filereadable = function(path)
  assert(path == expected)
  return 1
end
vim.cmd = function(command)
  edited = command
end
local common = require('srydell.compiler.common')
assert(common.get_current_compiler_name() == 'To show in status line')
common.edit_current_compiler()
assert(edited == 'edit ' .. expected)
vim.fn.filereadable, vim.cmd = old_readable, old_cmd
package.loaded.overseer = {
  list_tasks = function()
    return {}
  end,
  new_task = function(opts)
    assert(opts.strategy.tasks[1] == 'Name corresponding to overseer template')
    return { start = function() end }
  end,
}
package.loaded['srydell.compiler.output_window'] = { close_all = function() end }
common.run()

assert(loadstring(render('lua', 'lua/overseer/template/srydell/example.lua')))
local component = assert(loadstring(render('lua', 'lua/overseer/component/srydell/example.lua')))()
assert(type(component.constructor({}).on_init) == 'function')
assert(loadstring(render('lua', 'lua/srydell/snips/skeleton/example.lua')))
assert(render('lua', 'plain.lua') == nil)
assert(render('sh', 'script.sh'):find('#!/usr/bin/env bash', 1, true))
assert(render('python', 'script.py'):find('    pass', 1, true))
assert(render('swift', 'ContentView.swift'):find('struct ContentView: View', 1, true))
assert(render('swift', 'Views/Model.swift') == nil)
assert(render('cpp', 'include/example.hpp'):find('#pragma once', 1, true))
local header = render('cpp', 'standalone.h')
assert(not header:find('namespace', 1, true))
assert(header:find('#ifndef STANDALONE_H', 1, true))
assert(header == '#ifndef STANDALONE_H\n#define STANDALONE_H\n\n\n#endif // ifndef STANDALONE_H')
assert(not render('cpp', 'my-project/include/example.h'):find('namespace', 1, true))
assert(render('cpp', 'dsf/src/util/example.h'):find('namespace dsf::util', 1, true))
assert(render('cpp', 'dsf/src/util/test/test_example.cpp'):find('BOOST_AUTO_TEST_SUITE(example)', 1, true))
assert(render('cpp', 'dsf/src/util/example.cpp'):find('namespace dsf::util', 1, true))
assert(render('cpp', 'prototype/src/main.cpp') == '#include <iostream>\n\nint main() {\n  \n}')
assert(render('cpp', 'unknown/src/main.cpp') == nil)

-- No external fetch during validation; exercise fallback and decoded metadata.
local old_system = vim.fn.system
local payload = ''
vim.fn.system = function()
  return payload
end
assert(render('cpp', 'leetcode/src/123.cpp'):find('class Solution', 1, true))
payload = vim.json.encode({
  title = 'Angles < >',
  signature = { name = 'solve', return_type = 'vector<int>', params = { { type = 'vector<int>&', name = 'xs' } } },
  examples = {
    { arguments = { { name = 'xs', type = 'vector<int>', declaration = 'vector<int> xs{1};' } }, expected = '{1}' },
  },
})
local leetcode = render('cpp', 'leetcode/src/124.cpp')
assert(leetcode:find('vector<int> solve(vector<int>& xs)', 1, true))
assert(leetcode:find('solution.solve(xs)', 1, true))
payload = vim.json.encode({
  design = {
    class_name = 'Counter',
    constructor = { params = {} },
    methods = { { name = 'get', return_type = 'int', params = {} } },
    examples = {
      {
        steps = {
          { constructor = true, operation = 'Counter', arguments = {} },
          { operation = 'get', return_type = 'int', expected = '0' },
        },
      },
    },
  },
})
assert(render('cpp', 'leetcode/src/125.cpp'):find('auto ans2 = obj.get()', 1, true))
vim.fn.system = old_system

local old_scan = package.loaded['plenary.scandir']
package.loaded['plenary.scandir'] = {
  scan_dir = function(_, opts)
    return opts.only_dirs and { './folder<name>' } or { './file<name>.txt' }
  end,
}
local ignore = render('gitignore', '.gitignore')
assert(ignore:find('!file<name>.txt', 1, true))
assert(ignore:find('!folder<name>', 1, true))
package.loaded['plenary.scandir'] = old_scan

require('srydell.snips.skeleton')
vim.cmd('filetype on')
dofile('tests/skeleton_empty_buffer.lua')
