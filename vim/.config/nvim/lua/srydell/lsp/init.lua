require('mason').setup({
  pip = {
    install_args = {
      '--trusted-host',
      'pypi.org',
      '--trusted-host',
      'pypi.python.org',
      '--trusted-host',
      'files.pythonhosted.org',
    },
  },
})

require('mason-lspconfig').setup()

local lsp_servers = {
  'bashls',
  'clangd',
  'helm-ls',
  'jdtls',
  'lua_ls',
  'marksman',
  'neocmake',
  'pylsp',
  'texlab',
  'yaml-language-server',
  'kotlin-language-server',
  -- 'elixirls',
  -- 'perlnavigator',
  -- 'ruby-lsp',
}

require('mason-tool-installer').setup({
  -- a list of all tools you want to ensure are installed upon
  -- start; they should be the names Mason uses for each tool
  ensure_installed = {
    unpack(lsp_servers),

    -- Debug servers
    'codelldb',
    'debugpy',
    'bash-debug-adapter',

    -- Formatters
    'ruff',
    'shellcheck',
    'stylua',
  },
})

local lspconfig = require('lspconfig')
local lsp_util = require('lspconfig.util')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local opts = { silent = true }
local on_attach = function(_, bufnr)
  opts.buffer = bufnr

  -- opts.desc = 'Show line diagnostics'
  -- vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

  opts.desc = 'Rename declarator'
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  opts.desc = 'Apply code action'
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

  opts.desc = 'Go to definition'
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  opts.desc = 'Go to implementation'
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  opts.desc = 'Show references for declarator under cursor'
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  opts.desc = 'Show documentation for what is under cursor'
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
end

local util = require('srydell.util')
local no_auto_setup =
  { 'lua_ls', 'jdtls', 'ruby-lsp', 'helm-ls', 'yaml-language-server', 'bashls', 'kotlin-language-server' }
for _, lsp in ipairs(lsp_servers) do
  if not util.contains(no_auto_setup, lsp) then
    lspconfig[lsp].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
end

-- setup sourcekit
lspconfig.sourcekit.setup({
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
    unpack(capabilities),
  },
  on_attach = on_attach,
  cmd = {
    '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp',
  },
  filetypes = { 'swift' },
  root_dir = function(filename, _)
    return lsp_util.root_pattern('buildServer.json')(filename)
      or lsp_util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      or vim.fs.dirname(vim.fs.find('.git', { path = filename, upward = true })[1])
      or lsp_util.root_pattern('Package.swift')(filename)
  end,
})

-- setup lua_ls and enable call snippets
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';'),
      },
      diagnostics = { globals = { 'vim', 'hs' } },
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})

-- TODO: The shfmt executable is named platform depentent e.g. shfmt_v3.10.0_darwin_arm64
-- local shfmt = require('mason-registry').get_package('shfmt'):get_install_path()
lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    bashIde = {
      shellcheckPath = vim.fn.exepath('shellcheck'),
      shfmt = {
        path = 'shfmt',
      },
    },
  },
})

-- setup helm-ls
lspconfig.helm_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = 'yaml-language-server',
      },
    },
  },
})

-- setup yamlls
lspconfig.yamlls.setup({})

-- lspconfig.kotlin_language_server.setup({
--   filetypes = { 'kotlin', 'kt', 'kts' },
--   cmd = {
--     require('mason-registry').get_package('kotlin-language-server'):get_install_path()
--       .. '/server/bin/kotlin-language-server',
--   },
-- })
lspconfig.kotlin_language_server.setup({
  filetypes = { 'kotlin', 'kt', 'kts' },
  capabilities = capabilities,
})
