local constants = require('srydell.constants')

local util = require('srydell.util')

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

require('mason-tool-installer').setup({
  -- a list of all tools you want to ensure are installed upon
  -- start; they should be the names Mason uses for each tool
  ensure_installed = constants.tools,
})

local lspconfig = require('lspconfig')
local lsp_util = require('lspconfig.util')
local cmp_nvim_lsp = require('cmp_nvim_lsp')
local capabilities = cmp_nvim_lsp.default_capabilities()

local opts = { noremap = true, silent = true }
local on_attach = function(_, bufnr)
  opts.buffer = bufnr

  -- opts.desc = 'Show line diagnostics'
  -- vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

  -- if vim.bo.ft == 'cpp' then
  --   require('clangd_extensions.inlay_hints').setup_autocmd()
  --   require('clangd_extensions.inlay_hints').set_inlay_hints()
  -- end

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

local no_auto_setup = { 'lua_ls', 'jdtls', 'ruby-lsp', 'helm-ls', 'yaml-language-server' }
for _, lsp in ipairs(constants.lsp_servers) do
  if not util.contains(no_auto_setup, lsp) then
    lspconfig[lsp].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
end

-- setup sourcekit
lspconfig['sourcekit'].setup({
  capabilities = util.merge({
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  }, capabilities),
  on_attach = on_attach,
  cmd = {
    '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp',
  },
  filetypes = { 'swift' },
  root_dir = function(filename, _)
    return lsp_util.root_pattern('buildServer.json')(filename)
      or lsp_util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      or lsp_util.find_git_ancestor(filename)
      or lsp_util.root_pattern('Package.swift')(filename)
  end,
})

-- setup lua_ls and enable call snippets
lspconfig['lua_ls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})

-- setup helm-ls
lspconfig['helm_ls'].setup({
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
lspconfig['yamlls'].setup({})
