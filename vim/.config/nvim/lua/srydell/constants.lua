local lsp_servers = {
  'clangd', -- C++
  'lua_ls', -- Lua
  'neocmake', -- CMake, requires rust
  -- 'perlnavigator', -- perl, requires node
  'pylsp', -- Python
  -- 'bashls',   -- Bash, requires node
  -- 'biome',    -- JSON, requires node
  -- 'marksman', -- Markdown
  -- 'elixirls', -- Elixir
}

local debug_servers = {
  'codelldb',
  'debugpy',
}

local formatters = {
  'ruff', -- Python formatter/linter
  -- 'shellcheck', -- Shell linter
  'stylua', -- Lua formatter
}

local util = require('srydell.util')

local servers = util.merge(lsp_servers, debug_servers)

return {
  lsp_servers = lsp_servers,
  debug_servers = debug_servers,

  -- All tools
  tools = util.merge(servers, formatters),
}
