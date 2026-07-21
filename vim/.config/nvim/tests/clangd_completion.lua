-- Run with:
-- nvim --headless -u init.lua -l tests/clangd_completion.lua
local extension = require('lazy.core.config').plugins['clangd_extensions.nvim']
assert(extension._.loaded == nil, 'clangd_extensions loaded before a C-family buffer')
assert(
  vim.tbl_contains(require('blink.cmp.config').sources.default, 'lsp'),
  'Blink does not enable its LSP completion source'
)

local workspace_dir = vim.fn.tempname()
local project_dir = workspace_dir .. '/leetcode'
-- Reproduce ~/.clangd/index above a project-local compile_flags.txt. A flat,
-- priority-ordered marker list incorrectly selects workspace_dir as the root.
vim.fn.mkdir(workspace_dir .. '/.clangd/index', 'p')
vim.fn.mkdir(project_dir, 'p')
vim.fn.writefile({ '-std=c++20' }, project_dir .. '/compile_flags.txt')
vim.fn.writefile({
  '#include <vector>',
  'int main() {',
  '  std::vec',
  '}',
}, project_dir .. '/main.cpp')

-- Mason is intentionally disabled by the config in headless sessions, so
-- enable the already-configured server explicitly for this integration test.
vim.lsp.enable('clangd')
vim.cmd.edit(project_dir .. '/main.cpp')
assert(extension._.loaded ~= nil, 'clangd_extensions did not load for a C++ buffer')

local attached = vim.wait(10000, function()
  return #vim.lsp.get_clients({ bufnr = 0, name = 'clangd' }) > 0
end, 20)
assert(attached, 'clangd did not attach to the C++ buffer')

local client = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })[1]
assert(client.root_dir == project_dir, 'clangd selected the wrong project root: ' .. tostring(client.root_dir))
assert(client.server_capabilities.completionProvider, 'clangd did not advertise completion support')
assert(
  client.config.capabilities.textDocument.completion.completionItem.snippetSupport,
  'Blink completion capabilities were not sent to clangd'
)

local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
params.position = { line = 2, character = 10 }
params.context = { triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked }
local response = client:request_sync('textDocument/completion', params, 10000, 0)
assert(response and not response.err, 'clangd completion request failed')

local items = response.result.items or response.result
local labels = vim
  .iter(items)
  :map(function(item)
    return item.label
  end)
  :totable()
assert(
  vim.iter(labels):any(function(label)
    return vim.trim(label):match('^vector') ~= nil
  end),
  'clangd did not return std::vector completion; received: ' .. table.concat(labels, ', ')
)

client:stop(true)
vim.fn.delete(workspace_dir, 'rf')
print('clangd_completion: ok')
