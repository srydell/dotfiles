-- Run with:
-- nvim --headless -u init.lua -l tests/completion_sources.lua
local source_lib = require('blink.cmp.sources.lib')
local config = require('blink.cmp.config')

local function assert_sources(filetype, expected)
  vim.bo.filetype = filetype
  local actual = source_lib.get_enabled_provider_ids('default')
  assert(vim.deep_equal(actual, expected), filetype .. ' sources: ' .. vim.inspect(actual))
end

assert_sources('lua', { 'lazydev', 'lsp', 'copilot', 'snippets', 'buffer', 'path' })
assert_sources('python', { 'lsp', 'copilot', 'snippets', 'buffer', 'path' })
assert_sources('gitcommit', { 'buffer' })
assert_sources('dap-repl', { 'dap' })
assert_sources('dapui_watches', { 'dap' })
assert_sources('codecompanion', { 'codecompanion' })
assert_sources('codecompanion_input', { 'codecompanion' })

local plugins = require('lazy.core.config').plugins
assert(plugins['blink.compat'] == nil, 'blink.compat is still in the resolved plugin graph')
assert(plugins['cmp-dap'] == nil, 'cmp-dap is still in the resolved plugin graph')
assert(config.sources.providers.dap.module == 'blink-cmp-dap', 'DAP does not use the native Blink source')

vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'completion_source_word', '' })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local buffer_response
require('blink.cmp.sources.buffer')
  .new({
    get_bufnrs = function()
      return { vim.api.nvim_get_current_buf() }
    end,
    use_cache = false,
  })
  :get_completions({}, function(response)
    buffer_response = response
  end)
assert(
  vim.wait(1000, function()
    return buffer_response ~= nil
  end),
  'buffer source did not respond'
)
assert(
  vim.iter(buffer_response.items):any(function(item)
    return item.label == 'completion_source_word'
  end),
  'buffer source did not return a word from the current buffer'
)

vim.bo.filetype = 'completion-source-audit'
local luasnip = require('luasnip')
luasnip.add_snippets('completion-source-audit', {
  luasnip.snippet('audit_snippet', luasnip.text_node('expanded')),
})
local snippet_response
require('blink.cmp.sources.snippets').new({ preset = 'luasnip' }):get_completions({
  line = '',
  cursor = { 1, 1 },
}, function(response)
  snippet_response = response
end)
assert(snippet_response, 'snippet source did not respond')
assert(
  vim.iter(snippet_response.items):any(function(item)
    return item.label == 'audit_snippet'
  end),
  'snippet source did not return the LuaSnip snippet'
)

local path_dir = vim.fn.tempname()
vim.fn.mkdir(path_dir, 'p')
vim.fn.writefile({ 'documentation preview' }, path_dir .. '/source_target.txt')
local path_response
local path_source = require('blink.cmp.sources.path').new({
  get_cwd = function()
    return path_dir
  end,
})
path_source:get_completions({
  bufnr = 0,
  line = '"./sou',
  cursor = { 1, 6 },
  bounds = { start_col = 4, length = 3 },
}, function(response)
  path_response = response
end)
assert(
  vim.wait(1000, function()
    return path_response ~= nil
  end),
  'path source did not respond'
)
local path_item = vim.iter(path_response.items):find(function(item)
  return item.label == 'source_target.txt'
end)
assert(path_item, 'path source did not return the matching file')
local resolved_path_item
path_source:resolve(path_item, function(item)
  resolved_path_item = item
end)
assert(
  vim.wait(1000, function()
    return resolved_path_item ~= nil
  end),
  'path documentation did not resolve'
)
assert(resolved_path_item.documentation.value:find('documentation preview', 1, true), 'path preview was empty')
vim.fn.delete(path_dir, 'rf')

assert(source_lib.get_provider_by_id('copilot'), 'Copilot source failed to initialize')
vim.bo.filetype = 'dap-repl'
assert(not source_lib.get_provider_by_id('dap'):enabled(), 'DAP source enabled without an active debug session')

assert(type(config.cmdline.sources) == 'function', 'command-line source routing is not configured')
assert(vim.deep_equal(config.cmdline.sources(), { 'path', 'cmdline' }), 'Ex command sources are incorrect')

require('lazy').load({ plugins = { 'copilot.lua' } })
assert(
  config.sources.providers.codecompanion.module == 'codecompanion.providers.completion.blink',
  'CodeCompanion did not register its native Blink source'
)
assert(source_lib.get_provider_by_id('codecompanion'), 'CodeCompanion source failed to initialize')

print('completion_sources: ok')
