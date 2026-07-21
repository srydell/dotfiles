-- Run with:
-- nvim --headless -u init.lua -l tests/xcodebuild_lazy.lua
local plugin = require('lazy.core.config').plugins['xcodebuild.nvim']
assert(plugin._.loaded == nil, 'Xcodebuild loaded before opening a Swift buffer')

vim.bo.filetype = 'cpp'
assert(plugin._.loaded == nil, 'Xcodebuild loaded for a C++ buffer')
assert(vim.fn.maparg('<leader>xb', 'n') == '', 'Xcodebuild mapping leaked into C++')

vim.bo.filetype = 'swift'
assert(plugin._.loaded ~= nil, 'Xcodebuild did not load for a Swift buffer')
assert(vim.fn.maparg('<leader>xb', 'n') ~= '', 'Xcodebuild mapping missing from the first Swift buffer')

vim.cmd.enew()
vim.bo.filetype = 'cpp'
assert(vim.fn.maparg('<leader>xb', 'n') == '', 'Xcodebuild mapping leaked after the plugin loaded')

vim.cmd.enew()
vim.bo.filetype = 'swift'
assert(vim.fn.maparg('<leader>xb', 'n') ~= '', 'Xcodebuild mapping missing from a later Swift buffer')

print('xcodebuild_lazy: ok')
