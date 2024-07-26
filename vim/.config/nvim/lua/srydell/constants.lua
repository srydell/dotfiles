local lsp_servers = {
  'clangd', -- C++
  -- 'elixirls', -- Elixir
  'helm-ls', -- Helm
  'jdtls', -- Java
  'lua_ls', -- Lua
  'neocmake', -- CMake, requires rust
  'pylsp', -- Python
  'yaml-language-server', -- YAML
  -- 'perlnavigator', -- perl, requires node
  -- 'ruby-lsp', -- Ruby
  -- 'bashls',   -- Bash, requires node
  -- 'biome',    -- JSON, requires node
  -- 'marksman', -- Markdown
}

local debug_servers = {
  'codelldb',
  'debugpy',
  -- 'java-debug-adapter',
  -- 'java-test',
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

  icons = {
    debugging = '🐛',
    building = '🛠',
    up = '',
    down = '',
  },
}
