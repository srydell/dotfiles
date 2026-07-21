-- Run with:
-- nvim --headless -u init.lua -l tests/language_completion.lua
vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin:' .. vim.env.PATH

local function write_project(marker, filename, lines)
  local project_dir = vim.fn.tempname()
  vim.fn.mkdir(project_dir, 'p')
  vim.fn.writefile(marker == '.luarc.json' and { '{}' } or {}, project_dir .. '/' .. marker)
  vim.fn.writefile(lines, project_dir .. '/' .. filename)
  return project_dir, project_dir .. '/' .. filename
end

local function assert_completion(server, project_dir, filename, position, expected, require_documentation)
  vim.lsp.enable(server)
  vim.cmd.edit(filename)

  local attached = vim.wait(10000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = server }) > 0
  end, 20)
  assert(attached, server .. ' did not attach')

  local client = vim.lsp.get_clients({ bufnr = 0, name = server })[1]
  assert(client.root_dir == project_dir, server .. ' selected the wrong root: ' .. tostring(client.root_dir))
  assert(client.server_capabilities.completionProvider, server .. ' did not advertise completion support')
  assert(
    client.config.capabilities.textDocument.completion.completionItem.snippetSupport,
    'Blink completion capabilities were not sent to ' .. server
  )

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  params.position = position
  params.context = { triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked }
  local labels = {}
  local matched_item
  local completed = vim.wait(10000, function()
    local response = client:request_sync('textDocument/completion', params, 2000, 0)
    if not response or response.err or not response.result then
      return false
    end

    local items = response.result.items or response.result
    labels = vim
      .iter(items)
      :map(function(item)
        return vim.trim(item.label)
      end)
      :totable()
    matched_item = vim.iter(items):find(function(item)
      local label = vim.trim(item.label)
      return label == expected or vim.startswith(label, expected .. '(')
    end)
    return matched_item ~= nil
  end, 100)
  assert(completed, string.format('%s did not return %s; received: %s', server, expected, table.concat(labels, ', ')))

  if require_documentation and not matched_item.documentation then
    local resolved = client:request_sync('completionItem/resolve', matched_item, 5000, 0)
    matched_item = resolved and resolved.result or matched_item
  end
  if require_documentation then
    local documentation = matched_item.documentation
    local content = type(documentation) == 'table' and documentation.value or documentation
    assert(type(content) == 'string' and content ~= '', server .. ' completion documentation was empty')
  end

  client:stop(true)
  vim.fn.delete(project_dir, 'rf')
end

assert(vim.tbl_contains(require('blink.cmp.config').sources.default, 'lsp'), 'Blink LSP source is disabled')
local lua_sources = require('blink.cmp.config').sources.per_filetype.lua
assert(
  lua_sources.inherit_defaults and vim.tbl_contains(lua_sources, 'lazydev'),
  'LazyDev source is not enabled for Lua'
)

local lua_dir, lua_file = write_project('.luarc.json', 'main.lua', { 'local bufnr = vim.api.nvim_get_current_bu' })
assert_completion('lua_ls', lua_dir, lua_file, { line = 0, character = 41 }, 'nvim_get_current_buf', true)

local python_dir, python_file = write_project('pyproject.toml', 'main.py', { 'import pathlib', 'pathlib.Pa' })
assert_completion('pylsp', python_dir, python_file, { line = 1, character = 10 }, 'Path')

print('language_completion: ok')
