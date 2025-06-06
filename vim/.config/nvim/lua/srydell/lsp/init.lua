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

local lsp_servers = {
  'bashls',
  'clangd',
  'helm_ls',
  'jdtls',
  'lua_ls',
  'marksman',
  'neocmake',
  'pylsp',
  'texlab',
  'yamlls',
  'kotlin_language_server',
  'harper_ls',
  -- 'elixirls',
  -- 'perlnavigator',
  -- 'ruby-lsp',
}

local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup({
  automatic_enable = true,
  ensure_installed = lsp_servers,
  exclude = {
    'jdtls', -- conflicts with nvim-jdtls
  },
})

require('mason-tool-installer').setup({
  -- a list of all tools you want to ensure are installed upon
  -- start; they should be the names Mason uses for each tool
  ensure_installed = {
    -- Debug servers
    'codelldb',
    'debugpy',
    'bash-debug-adapter',

    -- Formatters
    'ruff',
    'isort',
    'black',
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

for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
  vim.lsp.config[server].on_attach = on_attach
end

-- Setup harper_ls and configure it to only use markdown files
vim.lsp.config.harper_ls = {
  filetypes = { 'markdown' },
}

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
